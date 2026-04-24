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

# Allow rootless user namespace creation (required for rootless runc on Ubuntu 24.04+)
if [ -f /proc/sys/kernel/apparmor_restrict_unprivileged_userns ]; then
    current_apparmor_userns_setting="$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns)"
    if [ "$current_apparmor_userns_setting" != "0" ]; then
        echo "NOTICE: Setting kernel.apparmor_restrict_unprivileged_userns=0 to allow rootless user namespace creation."
        echo "NOTICE: This relaxes a host-wide kernel security setting for the rest of the current machine session."
        echo "NOTICE: To revert this change later, run: sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=$current_apparmor_userns_setting"
        sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
    fi
fi

# Creates the NETCONFPATH folder
sudo mkdir -p "$NETCONFPATH"
sudo chown -R "$USER:" "$NETCONFPATH"
cat <<EOF >"${NETCONFPATH}/00-mynet.conf"
{
    "cniVersion": "0.4.0",
    "name": "$CNI_NAME",
    "type": "bridge",
    "bridge": "$BRIDGE_NAME",
    "isDefaultGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "$IPAM_SUBNET_CIDR"
    }   
}
EOF
