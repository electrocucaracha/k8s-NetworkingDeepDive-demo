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

# Creates the NETCONFPATH folder
sudo mkdir -p "$NETCONFPATH"
sudo chown -R "$USER:" "$NETCONFPATH"
cat << EOF > "${NETCONFPATH}/00-mynet.conf"
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
