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

# shellcheck source=manual/defaults.env
source defaults.env
# shellcheck source=manual/_utils.sh
source _utils.sh

function cleanup {
    info "Stopping $CONTAINERID container"
    if runc list | grep -q "^$CONTAINERID.*running"; then
        runc kill "$CONTAINERID" KILL
    fi
    until runc list | grep -q "^$CONTAINERID.*stopped"; do
        sleep 1
    done
    if [ -f /tmp/recvtty.pid ]; then
        kill -9 "$(cat /tmp/recvtty.pid)"
        rm -f /tmp/recvtty.pid
    fi
    if [ -S /tmp/tty.sock ]; then
        rm -f /tmp/tty.sock
    fi
    if runc list | grep -q "^$CONTAINERID"; then
        runc delete "$CONTAINERID"
    fi
}

trap cleanup EXIT

# Creates a pseudo-terminal for detached mode - https://github.com/opencontainers/runc/blob/v1.0.0-rc92/docs/terminals.md#detached
if [ ! -S /tmp/tty.sock ]; then
    (recvtty --pid-file /tmp/recvtty.pid --mode null /tmp/tty.sock &) &
fi
mkdir -p /tmp/images
pushd /tmp/images > /dev/null
skopeo copy docker://busybox:latest oci:busybox:latest > /dev/null
popd > /dev/null

pushd "$(mktemp -d)" > /dev/null
cp -r /tmp/images/busybox .
sudo umoci unpack --image busybox:latest bundle
sudo chown -R "$USER:" bundle/

# This script simulates the pause container
# NOTE: Pause container - https://www.ianlewis.org/en/almighty-pause-container
cat << EOF > bundle/rootfs/init.sh
#!/bin/sh

trap "echo 'Shutting down, got signal'" EXIT
trap "echo 'Error: infinite loop terminated'" EXIT
sleep infinity
EOF

# Creates a rootless OCI runtime config and include Network namespace creation.
runc spec --rootless
jq --argjson netType '{"type": "network" }' '.linux.namespaces += [$netType]' config.json > net_config.json
jq '.process.args += ["init.sh"]' net_config.json > bundle/config.json

info "Network namespaces before container creation:"
sudo ip netns
lsns --type net

# Start container
info "Starting the $CONTAINERID container..."
runc run --detach --bundle bundle --console-socket /tmp/tty.sock "$CONTAINERID"
popd > /dev/null

info "Processes list:"
ps -f -C runc -C sh
info "Container list:"
runc list

info "Network namespaces after container creation and before allocation:"
lsns --type net
sudo ip netns


# Assign container's net namespace
sudo mkdir -p /var/run/netns
sudo ln -sf "$(jq  -r '.namespace_paths.NEWNET' "/var/run/user/1000/runc/$CONTAINERID/state.json")" "$CNI_NETNS"

info "Network namespaces after allocation:"
sudo ip netns

info "Host Network state:"
ip addr
brctl show
info "Container Network state:"
runc exec "$CONTAINERID" ip addr

# Uses CNI_PATH, NETCONFPATH and CNI_IFNAME values
info "Adding network thru CNI tool:"
sudo -E cnitool add "$CNI_NAME" "$CNI_NETNS"

# Network bridge, veth pairs and MAC addresses have been created and configured
info "Host Network state:"
sudo ip netns
lsns --type net
ip addr
brctl show
brctl showmacs "$BRIDGE_NAME"
info "Container $CNI_IFNAME nic info:"
runc exec "$CONTAINERID" ip addr show "$CNI_IFNAME"

# Disconnect container from bridge
info "Droping network thru CNI tool:"
sudo -E cnitool del "$CNI_NAME" "$CNI_NETNS"

# Network bridge are kept and veth pairs and MAC addresses have been removed.
info "Host Network state:"
ip addr
brctl show
brctl showmacs "$BRIDGE_NAME"
info "Container Network state:"
runc exec "$CONTAINERID" ip addr

info "Containers list:"
runc list
