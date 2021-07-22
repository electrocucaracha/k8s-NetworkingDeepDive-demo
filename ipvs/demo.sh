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

# shellcheck source=ipvs/defaults.env
source defaults.env
# shellcheck disable=SC1091
source /opt/common/_utils.sh

function print_stats {
    sleep 5
    sudo ipvsadm --list --numeric --stats --rate
}

function generate_traffic {
    info "Generating HTTP traffic"
    for _ in {1..6}; do
        if [[ "${1:-false}" == "false" ]]; then
            curl -s "$SERVICE_ADDRESS"
        else
            sudo ip netns exec pod1 curl -s --connect-timeout 1 "$SERVICE_ADDRESS" ||:
        fi
        echo ""
    done
    print_stats
}

# Round Robin - Distributes jobs equally amongst the available real server
info "Using Round Robin scheduling algorithm"
generate_traffic

info "Increase pod1 weight"
ip_addr=${POD_SUBNET_PREFIX}$((1+1))
sudo ipvsadm --edit-server --tcp-service "$SERVICE_ADDRESS" --real-server "$ip_addr" --masquerading --weight 3

# Weighted Round Robin - Assigns jobs to real servers proportionally to there real servers’ weight.
sudo ipvsadm --edit-service --tcp-service "$SERVICE_ADDRESS" --scheduler wrr
sudo ipvsadm --list --numeric
info "Using Weighted Round Robin scheduling algorithm"
generate_traffic

# Restablish to Round Robin scheduling algorithm
sudo ipvsadm --edit-service --tcp-service "$SERVICE_ADDRESS" --scheduler rr

info "Validating communication between Pod and ClusterIP"
generate_traffic true

info "Creating IPVS dummy interface"
# The default dummy interface which ipvs service address will bind to it
sudo ip link add dev kube-ipvs0 type dummy
sudo ip addr add "$SERVICE_IP/32" dev kube-ipvs0

# Enable transparent masquerading and to facilitate Virtual Extensible
# LAN (VxLAN) traffic for communication between Network namespaces
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic
sudo modprobe br_netfilter
sudo sysctl --write net.bridge.bridge-nf-call-iptables=1
generate_traffic true

info "Enabiling Hairpin connections"
# Promiscuous mode is a mode causes the controller to pass all traffic it
# receives to the central processing unit (CPU) rather than passing only the
# frames that the controller is specifically programmed to receive.
sudo ip link set cbr0 promisc on
# Maintain connection tracking entries for connections handled by IPVS. This
# should be enabled if connections handled by IPVS are to be also handled by
# stateful firewall rules. That is, iptables rules that make use of connection
# tracking.
sudo sysctl --write net.ipv4.vs.conntrack=1
generate_traffic true
