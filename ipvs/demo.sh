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
    for _ in {1..12}; do
        curl -s "$SERVICE_ADDRESS"
        echo ""
    done
    print_stats
}

# Round Robin - Distributes jobs equally amongst the available real server
info "Using Round Robin scheduling algorithm"
generate_traffic

info "Increase svc1 weight"
ip_addr=${POD_SUBNET_PREFIX}$((1+1))
sudo ipvsadm --edit-server --tcp-service "$SERVICE_ADDRESS" --real-server "$ip_addr" --masquerading --weight 3
sudo ipvsadm --list --numeric

# Weighted Round Robin - Assigns jobs to real servers proportionally to there real servers’ weight.
sudo ipvsadm --edit-service --tcp-service "$SERVICE_ADDRESS" --scheduler wrr
info "Using Weighted Round Robin scheduling algorithm"
generate_traffic
