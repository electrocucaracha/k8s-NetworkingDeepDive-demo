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

# get_status() - Print the current status of the cluster
function get_status {
    printf "CPU usage: "
    grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage " %"}'
    printf "Memory free(Kb):"
    awk -v low="$(grep low /proc/zoneinfo | awk '{k+=$2}END{print k}')" '{a[$1]=$2}  END{ print a["MemFree:"]+a["Active(file):"]+a["Inactive(file):"]+a["SReclaimable:"]-(12*low);}' /proc/meminfo
    echo "Kubernetes Events:"
    kubectl get events -A --sort-by=".metadata.managedFields[0].time"
    echo "Kubernetes Resources:"
    kubectl get all -A -o wide
    echo "Kubernetes Pods:"
    kubectl describe pods
    echo "Kubernetes Nodes:"
    kubectl describe nodes
}

sudo modprobe br_netfilter

if [ -z "$(sudo docker images kindest/node:flannel -q)" ]; then
    sudo docker build --tag kindest/node:flannel --no-cache .
fi

trap get_status ERR
if ! sudo "$(command -v kind)" get clusters | grep -e k8s; then
    # editorconfig-checker-disable
    cat <<EOF | sudo kind create cluster --name k8s --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
networking:
  kubeProxyMode: "ipvs"
  disableDefaultCNI: true
nodes:
  - role: control-plane
    image: kindest/node:flannel
    extraMounts:
      - hostPath: /opt/containernetworking/plugins
        containerPath: /opt/cni/bin
  - role: worker
    image: kindest/node:flannel
    extraMounts:
      - hostPath: /opt/containernetworking/plugins
        containerPath: /opt/cni/bin
  - role: worker
    image: kindest/node:flannel
    extraMounts:
      - hostPath: /opt/containernetworking/plugins
        containerPath: /opt/cni/bin
EOF
    # editorconfig-checker-enable
    mkdir -p "$HOME/.kube"
    sudo cp /root/.kube/config "$HOME/.kube/config"
    sudo chown -R "$USER" "$HOME/.kube/"
    chmod 600 "$HOME/.kube/config"
    newgrp docker <<"EONG"
    flannel_imgs=$(grep " image:" kube-flannel.yaml | awk '{print $2}' | sort | uniq)
    demo_imgs=$(grep "^.*_img=" demo.sh | awk -F '=' '{ print $2}')
    for img in $flannel_imgs $demo_imgs; do
        docker pull $img
        # TODO: Investigate about this issue (https://github.com/kubernetes-sigs/kind/blob/v0.26.0/pkg/cluster/nodeutils/util.go#L95)
        kind load docker-image $img --name k8s ||:
    done
EONG
fi
kubectl apply -f ./kube-flannel.yaml

# Wait for node readiness
for node in $(kubectl get node -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
    kubectl wait --for=condition=ready "node/$node" --timeout=3m
done
# Wait for flannel service
kubectl rollout status daemonset.apps/kube-flannel-ds -n kube-flannel --timeout=3m
