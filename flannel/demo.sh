#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o xtrace
set -o errexit
set -o nounset

# shellcheck disable=SC1091
source /opt/common/_utils.sh

function _run_cmd {
    if [[ ${K8S_FEATURE-} == "-ephemeral" ]]; then
        kubectl debug "nodes/${1}" -ti --image ubuntu:20.04 -- chroot /host/ "${@:2}"
    else
        sudo docker exec "$1" bash -c "${*:2}"
    fi
}

info "Cluster info:"
kubectl get nodes -o custom-columns=name:.metadata.name,podCIDR:.spec.podCIDR,InternalIP:.status.addresses[0].address
kubectl get pods -A -o custom-columns=name:.metadata.name,podIP:.status.podIP,nodeName:.spec.nodeName
for worker in $(sudo docker ps --filter "name=k8s-worker*" --format "{{.Names}}"); do
    echo "=== $worker Worker node info ==="
    info "Flannel dynamic configuration"
    _run_cmd "$worker" cat /run/flannel/subnet.env
    info "Network IPv4 addresses"
    _run_cmd "$worker" ip -4 address
    info "VXLAN network devices"
    # Virtual Tunnel End Point(VTEP) is  an entity which originates and/or terminates VXLAN tunnels.
    _run_cmd "$worker" ip -details link show type vxlan
    info "Network routes"
    _run_cmd "$worker" ip route
    info "ARP cache entries"
    _run_cmd "$worker" ip -4 neigh
done

info "Pods creation"
kubectl run pinghost --image=busybox:1.35.0 --overrides='{"spec": {"nodeName": "k8s-worker2"}}' -- sleep infinity >/dev/null
trap 'kubectl delete pods --all >/dev/null' EXIT
kubectl wait --for=condition=ready pods pinghost --timeout=3m >/dev/null
pinghost_ip="$(kubectl get pod pinghost -o jsonpath='{.status.podIP}')"
kubectl run pingclient --image=busybox:1.35.0 --overrides='{"spec": {"nodeName": "k8s-worker"}}' -- ping "$pinghost_ip" >/dev/null
kubectl wait --for=condition=ready pods pingclient --timeout=3m >/dev/null

info "Traffic verification"
kubectl logs --tail=2 pingclient
peer_ifindex="$(kubectl exec pingclient -- ip link show eth0 | grep -o '@if.*:' | sed 's/@if//;s/://')"
# shellcheck disable=SC2016
nic='$(ip link show up type veth | grep -o -P "'$peer_ifindex": veth.*@\" | awk '{print substr(\$2, 1, length(\$2)-1)}')"
_run_cmd k8s-worker tcpdump -v -c 2 -i "$nic" icmp
_run_cmd k8s-worker tshark -V -c 2 -i "$nic" -Y icmp

info "Workers status after Pods creation"
for worker in $(sudo docker ps --filter "name=k8s-worker*" --format "{{.Names}}"); do
    echo "=== $worker Worker node info ==="
    info "Last reserved IP address allocated by host-local"
    # "host-local" CNI plugin allocates and maintains the IP addresses to pods.
    # cbr0 is the name defined in cni-conf.json configuration file
    _run_cmd "$worker" cat /var/lib/cni/networks/cbr0/last_reserved_ip.0
    info "Virtual Ethernet network devices connected to cni0"
    # A new vEth pair has been created for the pod
    _run_cmd "$worker" ip link show type veth | grep cni
    info "Bridge network devices"
    # The cni0 bridge has been created to connect pods within worker node
    _run_cmd "$worker" brctl show
    info "cni0 network routes"
    # A new route has been created to pod internal communication
    _run_cmd "$worker" ip route | grep cni0
done

echo "=== k8s-worker Worker node info ==="
info "MAC addresses learned by cni0"
_run_cmd k8s-worker brctl showmacs cni0
info "ARP cache entries to pinghost pod"
# shellcheck disable=SC2016
# shellcheck disable=SC2086
_run_cmd k8s-worker ip neigh show '$(ip route get '$pinghost_ip" | awk 'NR==1{print \$3}')"
info "Forwarding Database entries of flannel.1"
_run_cmd k8s-worker bridge fdb show brport flannel.1

echo "=== k8s-worker2 Worker node info ==="
info "Network device details of flannel.1"
_run_cmd k8s-worker2 ip -detail link show flannel.1
info "Flannel's VTEP MAC address stored into Annotations"
kubectl get node k8s-worker2 -o jsonpath='{.metadata.annotations.flannel\.alpha\.coreos\.com/backend-data}'
info "Flannel's Public IP address stored into Annotations"
kubectl get node k8s-worker2 -o jsonpath='{.metadata.annotations.flannel\.alpha\.coreos\.com/public-ip}'
