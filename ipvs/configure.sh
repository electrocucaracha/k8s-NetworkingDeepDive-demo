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

# Enable IPVS Kernel module
sudo modprobe ip_vs

# Setup a new IPVS service
sudo ipvsadm --clear
sudo ipvsadm --add-service --tcp-service "$SERVICE_ADDRESS" --scheduler rr

# Configure demo services
sudo docker pull nginx:1.20.0 > /dev/null
for i in {1..3}; do
    mkdir -p "/tmp/srv$i"
    echo "This is service #$i" > "/tmp/srv$i/index.html"
    if [[ -z $(sudo docker ps -aqf "name=svc$i") ]]; then
        sudo docker run --rm --detach \
        --volume "/tmp/srv$i:/usr/share/nginx/html" --name "svc$i" nginx:1.20.0
    fi
    ip_addr="$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "svc$i")"
    sudo ipvsadm --add-server --tcp-service "$SERVICE_ADDRESS" \
    --real-server "$ip_addr" --masquerading
done

# Virtual Server table
sudo ipvsadm --list --numeric
