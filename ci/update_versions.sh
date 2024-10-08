#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2021
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o errexit
set -o pipefail
if [[ ${DEBUG:-false} == "true" ]]; then
    set -o xtrace
fi

function get_version {
    local type="$1"
    local name="$2"
    local version=""
    local attempt_counter=0
    readonly max_attempts=5

    until [ "$version" ]; do
        version=$("_get_latest_$type" "$name")
        if [ "$version" ]; then
            break
        elif [ ${attempt_counter} -eq ${max_attempts} ]; then
            echo "Max attempts reached"
            exit 1
        fi
        attempt_counter=$((attempt_counter + 1))
        sleep $((attempt_counter * 2))
    done

    echo "${version#v}"
}

function _get_latest_github_release {
    url_effective=$(curl -sL -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")
    if [ "$url_effective" ]; then
        echo "${url_effective##*/}"
    fi
}

function _get_latest_docker_tag {
    curl -sfL "https://registry.hub.docker.com/v2/repositories/$1/tags?page_size=1024" | python -c 'import json,sys,re;versions=[obj["name"] for obj in json.load(sys.stdin)["results"] if re.match("^v?(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$",obj["name"])];print("\n".join(versions))' | uniq | sort -rn | head -n 1
}

function _get_latest_go {
    stable_version="$(curl -sL https://golang.org/VERSION?m=text)"
    if [ "$stable_version" ]; then
        echo "${stable_version#go}"
    fi
}

trap "make fmt" EXIT

eval "$(curl -fsSL https://raw.githubusercontent.com/electrocucaracha/pkg-mgr_scripts/master/ci/pinned_versions.env)"

sed -i "s|PKG_FLANNEL_VERSION:-.*|PKG_FLANNEL_VERSION:-$PKG_FLANNEL_VERSION}|g" flannel/install.sh

# Update KinD node image version
kind_version="$(get_version docker_tag kindest/node)"
find . -type f -name Dockerfile -exec sed -i "s|FROM kindest/node:v.*|FROM kindest/node:v$kind_version|g" {} \;

# Update Busybox image version
busybox_version="$(get_version docker_tag library/busybox)"
find . -type f -name '*.sh' -not -path ./ci/\* -exec sed -i "s/busybox:[0-9]*\\.[0-9]*\\.[0-9]*/busybox:$busybox_version/g" {} \;

# Update umoci
sed -i "s|umoci/releases/download/v.*|umoci/releases/download/v$(get_version github_release opencontainers/umoci)/umoci.amd64|g" pause/install.sh

# Update runC
sed -i "s/runc --version | awk 'NR==1{print \$3}')\" != \".*/runc --version | awk 'NR==1{print \$3}')\" != \"${PKG_RUNC_VERSION}\" ]; then/g" pause/install.sh
sed -i "s|opencontainers/runc/releases/download/.*|opencontainers/runc/releases/download/v${PKG_RUNC_VERSION}/runc.amd64|g" pause/install.sh
sed -i "s|opencontainers/runc/contrib/cmd/recvtty@v.*|opencontainers/runc/contrib/cmd/recvtty@v${PKG_RUNC_VERSION}|g" pause/install.sh

# Update cnitool
sed -i "s|containernetworking/cni/cnitool@v.*|containernetworking/cni/cnitool@v$(get_version github_release containernetworking/cni)|g" pause/install.sh

# Update flannel definition
wget -q -O ./flannel/kube-flannel.yaml https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Update GitHub Action commit hashes
gh_actions=$(grep -r "uses: [a-zA-Z\-]*/[\_a-z\-]*@" .github/ | sed 's/@.*//' | awk -F ': ' '{ print $3 }' | sort -u)
for action in $gh_actions; do
    commit_hash=$(git ls-remote "https://github.com/$action" | grep 'refs/tags/[v]\?[0-9][0-9\.]*$' | sed 's|refs/tags/[vV]\?[\.]\?||g' | sort -u -k2 -V | tail -1 | awk '{ printf "%s # %s\n",$1,$2 }')
    # shellcheck disable=SC2267
    grep -ElRZ "uses: $action@" .github/ | xargs -0 -l sed -i -e "s|uses: $action@.*|uses: $action@$commit_hash|g"
done

# Update cdebug
sed -i "s|CDEBUG_VERSION:-.*|CDEBUG_VERSION:-$(get_version github_release iximiuz/cdebug)}|g" flannel/install.sh
