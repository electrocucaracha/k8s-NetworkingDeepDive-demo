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

# create_netns() - Creates and initializes a Network namespace
function create_netns {
	local netns_name="$1"

	sudo ip netns add "$netns_name"

	# Enable loopback device
	sudo ip netns exec "$netns_name" ip link set dev lo up

	# Configure DNS server
	sudo mkdir -p "/etc/netns/$netns_name"
	echo "nameserver 1.1.1.1" | sudo tee -a "/etc/netns/$netns_name/resolv.conf"
}

# netns_exec() - Executes a command in a given Network namespace
function netns_exec {
	local netns_name="$1"

	if ! sudo ip netns | grep -q "$netns_name"; then
		create_netns "$netns_name"
	fi
	sudo ip netns exec "$netns_name" "${@:2}"
}

# add_endpoint() - Adds a new entry in the service table
function add_endpoint {
	local ip_address="$1"

	sudo ipset add KUBE-LOOP-BACK "$ip_address,tcp:80,$ip_address"
	sudo ipvsadm --add-server --tcp-service "$SERVICE_ADDRESS" \
		--real-server "${ip_address}:80" --masquerading
}

# create_sandbox() - Initializes a Pod
function create_sandbox {
	local id="$1"
	pod_name="pod$id"
	ip_address=${POD_SUBNET_PREFIX}$((id + 1))
	html="This is service #$id"

	# Starts Web server
	netns_exec "$pod_name" nohup bash -c "(while true; do echo -e 'HTTP/1.1 200 OK\r\nContent-Length: ${#html}\r\nConnection: close\r\n\n${html}'| timeout 1 nc -N -lp 80 ; done) &" 1>/dev/null

	# Create veth pair and connect namespace with bridge
	sudo ip link add "veth$id" type veth peer name "veth${id}p"

	sudo ip link set dev "veth${id}" master cni0
	sudo ip link set dev "veth${id}" up

	sudo ip link set dev "veth${id}p" netns "$pod_name"
	# Rename container virtual nic
	sudo ip netns exec "$pod_name" ip link set dev "veth${id}p" down
	sudo ip netns exec "$pod_name" ip link set dev "veth${id}p" name eth0

	# Configure veth connected to the namespace
	netns_exec "$pod_name" ip link set dev eth0 up
	netns_exec "$pod_name" ip address add "$ip_address/24" dev eth0
	netns_exec "$pod_name" ip route add default via "${POD_SUBNET_GW}"

	add_endpoint "$ip_address"
}

# Configure Pod Subnet Bridge
if ! ip addr show cni0; then
	sudo ip link add dev cni0 type bridge
	sudo ip address add "${POD_SUBNET_GW}/24" dev cni0
	sudo ip link set dev cni0 up

	# Forward traffic from one veth to another veth

	sudo ipset create KUBE-LOOP-BACK hash:ip,port,ip
	# Enable IPv4 Forwarding
	# IP forwarding enables receiving traffic on our virtual ethernet device and
	# forwarding it to another device and vice versa.
	sudo sysctl --write net.ipv4.ip_forward=1
	# Masquerade for solving hairpin purpose
	sudo iptables --table nat --append POSTROUTING --match set --match-set KUBE-LOOP-BACK dst,dst,src --jump MASQUERADE
fi

# Enable IPVS Kernel module
sudo modprobe ip_vs

# Setup a new IPVS service
sudo ipvsadm --clear
sudo ipvsadm --add-service --tcp-service "$SERVICE_ADDRESS" --scheduler rr

# Configure demo services
for i in {1..3}; do
	create_sandbox "$i"
done

# Veth pair
ip link show type veth

# Virtual Server table
sudo ipvsadm --list --numeric

# IP set list
sudo ipset list

# Show IP tables
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v

# Show ARP tables
ip neigh show dev cni0
