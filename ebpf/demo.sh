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

function _ping {
    local service=$1
    local ip=$2

    info "Ping $service service"
    sudo -E perf trace -e "net:*" -o "$HOME/events.txt" ping -c 3 "$ip" | grep "time="
    sed -i 's|^.*ping/[0-9]* ||;s|skbaddr.*$||;s|napi_id.*$||' "$HOME/events.txt"
    sort <"$HOME/events.txt" | uniq >"$HOME/events_$service.txt"
}

_ping original "$(hostname -I | awk '{ print $1}')"

sudo docker run --name bypass --rm -d -v /sys:/sys --privileged ebpf:network
trap 'sudo docker kill bypass' EXIT

_ping bypass "$(sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' bypass)"

info "Bypass logs"
sudo docker logs bypass

info "Trace events difference"
comm -3 ~/events_original.txt ~/events_bypass.txt
