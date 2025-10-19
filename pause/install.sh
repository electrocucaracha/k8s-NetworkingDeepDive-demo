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

if ! command -v curl; then
    # shellcheck disable=SC1091
    source /etc/os-release || source /usr/lib/os-release
    case ${ID,,} in
    ubuntu | debian)
        sudo apt-get update
        sudo apt-get install -y -qq -o=Dpkg::Use-Pty=0 --no-install-recommends curl
        ;;
    esac
fi
# Install dependencies
pkgs=""
if ! command -v go; then
    pkgs+=" go-lang build-essential"
fi
if ! command -v brctl; then
    pkgs+=" bridge-utils"
fi
if [ ! -d "$PKG_CNI_PLUGINS_FOLDER" ]; then
    pkgs+=" cni-plugins"
fi
# NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
curl -fsSL http://bit.ly/install_pkg | PKG_COMMANDS_LIST="jq,skopeo" PKG=$pkgs bash
if ! command -v go; then
    # shellcheck disable=SC1091
    source /etc/profile.d/path.sh
fi

# umoci - Modifies Open Container Images
if ! command -v umoci; then
    sudo curl -o /usr/bin/umoci -sL https://github.com/opencontainers/umoci/releases/download/v0.6.0/umoci.linux.amd64
    sudo chmod +x /usr/bin/umoci
fi

# cnitool - Executes a CNI configuration
if ! command -v cnitool; then
    go install github.com/containernetworking/cni/cnitool@v1.3.0
    sudo mv ~/go/bin/cnitool /usr/bin/
fi

# runc - CLI tool for spawning and running containers according to the OCI specification.
if ! command -v runc || [ "$(runc --version | awk 'NR==1{print $3}')" != "1.3.0" ]; then
    sudo curl -o /usr/bin/runc -L https://github.com/opencontainers/runc/releases/download/v1.3.0/runc.amd64
    sudo chmod +x /usr/bin/runc
fi

# recvtty - Reference implementation of a consumer of runC's --console-socket API
if ! command -v recvtty; then
    go install github.com/opencontainers/runc/tests/cmd/recvtty@v1.2.4
    sudo mv ~/go/bin/recvtty /usr/bin/
fi
