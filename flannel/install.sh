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

export PKG_FLANNEL_VERSION=${PKG_FLANNEL_VERSION:-1.2.0}
export PKG_CNI_PLUGINS_INSTALL_FLANNEL=true
export PKG="cni-plugins"
export PKG_COMMANDS_LIST="docker,kind,kubectl"
export PKG_KREW_PLUGINS_LIST=" "

# shellcheck disable=SC1091
source /etc/os-release || source /usr/lib/os-release
case ${ID,,} in
ubuntu | debian)
    if command -v systemd-resolve && (! systemd-resolve --status | grep -q 1.1.1.1); then
        sudo systemd-resolve --interface "$(ip route get 1.1.1.1 | grep "^1." | awk '{ print $5 }')" --set-dns 1.1.1.1
    fi
    if ! command -v curl; then
        sudo apt-get update -qq >/dev/null
        sudo apt-get install -y -qq -o=Dpkg::Use-Pty=0 curl
    fi
    ;;
esac

# Install dependencies
# NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
curl -fsSL http://bit.ly/install_pkg | bash
