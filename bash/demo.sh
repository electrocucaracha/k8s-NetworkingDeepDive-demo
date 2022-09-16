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

kubectl run test --image=busybox:1.35.0 -- sleep infinity
trap 'kubectl delete pod test' EXIT
kubectl wait --for=condition=Ready pod test

info "Getting the IP address assigned to the Pod"
kubectl exec test -- ip address show eth0

info "Show IP routes"
kubectl exec test -- ip route show

info "Checking North-South Communication"
kubectl exec test -- ping -c1 google.com

for node in $(sudo docker ps --filter "name=k8s-*" --format "{{.Names}}"); do
    sudo docker exec "$node" cat /var/log/bash-cni-plugin.log
done
