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

# create_sandbox() - Initializes a Pod
function create_sandbox {
    local id="$1"
    pod_name="pod$id"
    ip_address=${POD_SUBNET_PREFIX}$((id+1))
    html="This is service #$id"

    # Create Network namespace
    sudo ip netns add "$pod_name"

    # Enable loopback device
    sudo ip netns exec "$pod_name" ip link set dev lo up

    # Configure DNS server
    sudo mkdir -p "/etc/netns/$pod_name"
    echo "nameserver 1.1.1.1" | sudo tee -a "/etc/netns/$pod_name/resolv.conf"

    # Starts Web server
    sudo ip netns exec "$pod_name" nohup bash -c "(while true; do echo -e 'HTTP/1.1 200 OK\r\nContent-Length: ${#html}\r\nConnection: close\r\n\n${html}'| timeout 1 nc -N -lp 80 ; done) &" 1> /dev/null

    # Create veth pair and connect namespace with bridge
    sudo ip link add "veth$id" type veth peer name "veth${id}p"
    sudo ip link set dev "veth${id}" master cbr0
    sudo ip link set dev "veth${id}" up
    sudo ip link set dev "veth${id}p" netns "$pod_name"

    # Configure veth connected to the namespace
    sudo ip netns exec "$pod_name" ip link set dev "veth${id}p" up
    sudo ip netns exec "$pod_name" ip address add "$ip_address/24" dev "veth${id}p"
    sudo ip netns exec "$pod_name" ip route add default via "${POD_SUBNET_GW}"

    # Add Endpoint to the Service
    sudo ipvsadm --add-server --tcp-service "$SERVICE_ADDRESS" \
    --real-server "$ip_address:80" --masquerading
}

# Enable IPv4 Forwarding
sudo sysctl --write net.ipv4.ip_forward=1
sudo sysctl -p

# Configure Pod Subnet Bridge
sudo ip link add dev cbr0 type bridge
sudo ip address add "${POD_SUBNET_GW}/24" dev cbr0
sudo ip link set dev cbr0 up

sudo iptables --table filter --append FORWARD --in-interface cbr0 --jump ACCEPT
sudo iptables --table filter --append FORWARD --out-interface cbr0 --jump ACCEPT
sudo iptables --table nat --append POSTROUTING --source "${POD_SUBNET_PREFIX}0/24" --jump MASQUERADE

# Enable IPVS Kernel module
sudo modprobe ip_vs

# Setup a new IPVS service
sudo ipvsadm --clear
sudo ipvsadm --add-service --tcp-service "$SERVICE_ADDRESS" --scheduler rr

# Configure demo services
for i in {1..3}; do
    create_sandbox "$i"
done

# Virtual Server table
sudo ipvsadm --list --numeric
