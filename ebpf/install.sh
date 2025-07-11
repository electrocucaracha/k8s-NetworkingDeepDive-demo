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

pkg="linux-tools-$(uname -r)"
if ! command -v docker; then
	pkg+=" docker"
fi
# NOTE: Shorten link -> https://github.com/electrocucaracha/pkg-mgr_scripts
curl -fsSL http://bit.ly/install_pkg | PKG=$pkg bash
