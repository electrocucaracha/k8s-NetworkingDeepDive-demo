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

# shellcheck source=pause/defaults.env
source defaults.env
# shellcheck disable=SC1091
source /opt/common/_utils.sh

function cleanup {
    info "Stopping $CONTAINERID container"
    if runc --root "$HOME/.runc" list | grep -q "^$CONTAINERID.*running"; then
        runc --root "$HOME/.runc" kill "$CONTAINERID" KILL
    fi

    attempt_counter=0
    max_attempts=15
    until runc --root "$HOME/.runc" list | grep -q "^$CONTAINERID.*stopped"; do
        if [ ${attempt_counter} -eq ${max_attempts} ]; then
            echo "Max attempts reached"
            return
        fi
        attempt_counter=$((attempt_counter + 1))
        sleep 1
    done
    if [ -f /tmp/recvtty.pid ]; then
        kill -9 "$(cat /tmp/recvtty.pid)"
        rm -f /tmp/recvtty.pid
    fi
    if [ -S /tmp/tty.sock ]; then
        rm -f /tmp/tty.sock
    fi
    if runc --root "$HOME/.runc" list | grep -q "^$CONTAINERID"; then
        runc --root "$HOME/.runc" delete "$CONTAINERID"
    fi
}

trap cleanup EXIT

# NOTE: https://github.com/opencontainers/runc/blob/v1.0.0-rc92/docs/terminals.md#detached
if [ ! -S /tmp/tty.sock ]; then
    info "Creating pseudo-terminal in detached mode"
    (recvtty --pid-file /tmp/recvtty.pid --mode null /tmp/tty.sock &) &
fi

if [ ! -d /tmp/images/busybox/ ] || [ -z "$(ls -A /tmp/images/busybox)" ]; then
    info "Pulling busybox image"
    mkdir -p /tmp/images
    pushd /tmp/images >/dev/null
    skopeo copy docker://busybox:1.36.0 oci:busybox:1.36.0 >/dev/null
    popd >/dev/null
fi

pushd "$(mktemp -d)" >/dev/null
cp -r /tmp/images/busybox .
sudo umoci unpack --image busybox:1.36.0 bundle
sudo chown -R "$USER:" bundle/

# This script simulates the pause container
# NOTE: Pause container - https://www.ianlewis.org/en/almighty-pause-container
cat <<EOF >bundle/rootfs/init.sh
#!/bin/sh

trap "echo 'Shutting down, got signal'" EXIT
trap "echo 'Error: infinite loop terminated'" ERR
echo "Starting pause container"
sleep infinity
EOF

# Creates a rootless OCI runtime config and include Network namespace creation.
runc spec --rootless
jq --argjson netType '{"type": "network" }' '.linux.namespaces += [$netType]' config.json >net_config.json
jq '.process.args += ["init.sh"]' net_config.json >bundle/config.json

info "Network namespaces before container creation:"
sudo ip netns
lsns --type net

# Start container
info "Starting the $CONTAINERID container..."
runc --root "$HOME/.runc" run --detach --bundle bundle --console-socket /tmp/tty.sock "$CONTAINERID"
popd >/dev/null

info "Processes list:"
ps -f -C runc -C sh
info "Container list:"
runc --root "$HOME/.runc" list

info "Network namespaces after container creation and before allocation:"
lsns --type net
sudo ip netns

# Assign container's net namespace
sudo mkdir -p /var/run/netns
sudo ln -sf "$(jq -r '.namespace_paths.NEWNET' "$HOME/.runc/$CONTAINERID/state.json")" "$CNI_NETNS"

info "Network namespaces after allocation:"
sudo ip netns

info "Host Network state:"
ip addr
brctl show
info "Container Network state:"
runc --root "$HOME/.runc" exec "$CONTAINERID" ip addr

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
runc --root "$HOME/.runc" exec "$CONTAINERID" ip addr show "$CNI_IFNAME"

# Disconnect container from bridge
info "Droping network thru CNI tool:"
sudo -E cnitool del "$CNI_NAME" "$CNI_NETNS"

# Network bridge are kept and veth pairs and MAC addresses have been removed.
info "Host Network state:"
ip addr
brctl show
brctl showmacs "$BRIDGE_NAME"
info "Container Network state:"
runc --root "$HOME/.runc" exec "$CONTAINERID" ip addr

info "Containers list:"
runc --root "$HOME/.runc" list
