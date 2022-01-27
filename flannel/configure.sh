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

trap get_status ERR
if ! sudo "$(command -v kind)" get clusters | grep -e k8s; then
    newgrp docker <<EONG
    kind create cluster --name k8s --config=./kind-config${K8S_FEATURE:-}.yml
    for img in quay.io/coreos/flannel:v0.14.0 ubuntu:20.04 busybox:1.34; do
        docker pull \$img
        kind load docker-image \$img --name k8s
    done
EONG
fi
kubectl apply -f ./kube-flannel.yaml

# Install Network tooling
for worker in $(sudo docker ps --filter "name=k8s-worker*" --format "{{.Names}}"); do
    sudo docker exec "$worker" bash -c 'apt-get update && apt-get install -y --no-install-recommends bridge-utils tcpdump'
done

# Wait for node readiness
for node in $(kubectl get node -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
    kubectl wait --for=condition=ready "node/$node" --timeout=3m
done
