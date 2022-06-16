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

function _get_pod_cidr {
    pod_cidr=""
    attempt_counter=0
    max_attempts=5

    until [ "$pod_cidr" ]; do
        pod_cidr=$(kubectl get node "$1" -o jsonpath='{.spec.podCIDR}')
        if [ "$pod_cidr" ]; then
            echo "$pod_cidr"
            break
        elif [ ${attempt_counter} -eq ${max_attempts} ];then
            echo "Max attempts reached"
            exit 1
        fi
        attempt_counter=$((attempt_counter+1))
        sleep $((attempt_counter*2))
    done
}

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
    kind create cluster --name k8s --config=./kind-config.yml
EONG
fi

for node in $(sudo docker ps --filter "name=k8s-*" --format "{{.Names}}"); do
    pod_cidr=$(_get_pod_cidr "$node")
    cat << EOF > /tmp/10-bash-cni-plugin.conf
{
  "cniVersion": "0.3.1",
  "name": "mynet",
  "type": "bash-cni",
  "network": "10.244.0.0/16",
  "subnet": "$pod_cidr"
}
EOF
    cloud_init="
apt-get update && apt-get install -y --no-install-recommends bridge-utils jq prips
brctl addbr cni0
ip link set cni0 up
ip addr add ${pod_cidr%.*}.1/24 dev cni0
"
    sudo docker cp /tmp/10-bash-cni-plugin.conf "$node":/etc/cni/net.d/10-bash-cni-plugin.conf
    sudo docker exec "$node" bash -c "$cloud_init"
    sudo docker exec "$node" ln -s /opt/cni/bash/bin/plugin.sh /opt/cni/bin/bash-cni
done

# Wait for node readiness
for node in $(kubectl get node -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'); do
    kubectl wait --for=condition=ready "node/$node" --timeout=3m
done

kubectl wait --for=condition=Ready pods --all --all-namespaces
