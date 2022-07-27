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
set -o errexit
set -o nounset

if [[ "${DEBUG:-false}" == "true" ]]; then
    set -o xtrace
fi

reserved_ips_file=/tmp/reserved_ips # all reserved ips will be stored there
all_ips_file=/tmp/all_ips
rollback="echo 'Rolling back actions';"

# debug() - This function prints an information message in the standard output
function debug {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        _print_msg "DEBUG" "$1"
    fi
}

# info() - This function prints an information message in the standard output
function info {
    _print_msg "INFO" "$1"
}

function error {
    _print_msg "ERROR" "$1"
    exit 1
}

function _print_msg {
    printf "\n%s - %s: %s" "$(date +%H:%M:%S)" "$1" "$2"
}

function allocate_ip {
    local subnet="$1"
    local output=""

    all_ips=$(_get_all_ip_list "$subnet")
    # shellcheck disable=SC2206
    all_ips=(${all_ips[@]})
    if (( ${#all_ips[@]} == 0 )); then
        [ -f "$all_ips_file" ] && rm "$all_ips_file"
        error "The IP addresses list is empty"
    fi
    output+="${all_ips[1]}\n"
    reserved_ips=$(_get_reserved_ip_list "${all_ips[0]}" "${all_ips[1]}")

    for ip in "${all_ips[@]}"; do
        if [[ "${reserved_ips[*]}" != *${ip}* ]]; then
            echo "$ip" >> $reserved_ips_file
            output+="$ip\n"
            break
        fi
    done

    echo -e "$output"
}

function _get_all_ip_list {
    if [ ! -f "$all_ips_file" ]; then
        prips "$1" > "$all_ips_file"
    fi
    cat "$all_ips_file"
}

function _get_reserved_ip_list {
    reserved_ips=$(cat $reserved_ips_file 2> /dev/null || printf '%s\n' "$@" )
    # shellcheck disable=SC2206
    reserved_ips=(${reserved_ips[@]})
    printf '%s\n' "${reserved_ips[@]}" | sort | uniq | tee  $reserved_ips_file
}

function _get_rand_if_name {
    # shellcheck disable=SC2005
    echo "$(tr -dc 'A-F0-9' < /dev/urandom  | head -c4)"
}

function _add_rollback {
    rollback+="$1"
    # shellcheck disable=SC2064
    trap "$rollback" ERR
}

function add {
    subnet=$(echo "$stdin" | jq -r ".subnet")
    subnet_mask_size="${subnet#*/}"

    # IPAM
    info "Discover IP addresses"
    output=$(allocate_ip "$subnet")
    # shellcheck disable=SC2206
    output=(${output[@]})
    gw_ip=${output[0]}
    debug "gw_ip: $gw_ip"
    container_ip=${output[1]}
    if [[ -z "$container_ip" ]]; then
        [ -f "$reserved_ips_file" ] && rm "$reserved_ips_file"
        error "It couldn't discover an IP address for the container"
    fi
    debug "container_ip: $container_ip"
    _add_rollback "sed -i \"/$container_ip/d\" $reserved_ips_file;"

    info "Binding IP address"
    if_name="$(_get_rand_if_name)"
    host_if_name="veth$if_name"
    tmp_if_name="tmp$if_name"
    echo ""
    # CNI_CONTAINERID: Container ID.
    if ip link show type veth "$tmp_if_name" > /dev/null; then
        error "The $CNI_CONTAINERID container is unable to use $tmp_if_name interface"
    fi
    debug "host_if_name: $host_if_name"
    ip link add "$tmp_if_name" type veth peer name "$host_if_name"
    _add_rollback "ip link delete $tmp_if_name;"

    info "Connecting $host_if_name to cni0"
    ip link set "$host_if_name" up
    ip link set "$host_if_name" master cni0
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo ""
        brctl show cni0
    fi

    # NOTE: Enable ip netns access to CNI_NETNS namespace
    mkdir -p /var/run/netns/
    # CNI_NETNS: A reference to the container’s “isolation domain”.
    ln -sfT "$CNI_NETNS" "/var/run/netns/$CNI_CONTAINERID"
    _add_rollback "rm -rf /var/run/netns/$CNI_CONTAINERID;"

    info "Setting $tmp_if_name of $CNI_CONTAINERID container"
    ip link set "$tmp_if_name" netns "$CNI_CONTAINERID"

    # CNI_IFNAME: Name of the interface to create inside the container
    ip netns exec "$CNI_CONTAINERID" ip link set "$tmp_if_name" name "$CNI_IFNAME"
    ip netns exec "$CNI_CONTAINERID" ip link set "$CNI_IFNAME" up
    ip netns exec "$CNI_CONTAINERID" ip addr add "$container_ip/$subnet_mask_size" dev "$CNI_IFNAME"
    ip netns exec "$CNI_CONTAINERID" ip route add default via "$gw_ip" dev "$CNI_IFNAME"

    mac=$(ip netns exec "$CNI_CONTAINERID" ip link show "$CNI_IFNAME" | awk '/ether/ {print $2}')
    sdtout="{\"cniVersion\": \"0.3.1\",
    \"interfaces\": [{\"name\": \"$CNI_IFNAME\",\"mac\": \"$mac\",\"sandbox\": \"$CNI_NETNS\"}],
    \"ips\": [{\"version\": \"4\",\"address\": \"$container_ip/$subnet_mask_size\",
    \"gateway\": \"$gw_ip\",\"interface\": 0}]}"
    debug "sdtout: $(echo "$sdtout" | jq -r .)"
    echo "$sdtout" >&3
}

function del {
    ip=$(ip netns exec "$CNI_CONTAINERID" ip addr show "$CNI_IFNAME" | awk '/inet / {print $2}' | sed  s%/.*%% || echo "")
    debug "ip: $ip"
    if [ -n "$ip" ]; then
        sed -i "/$ip/d" $reserved_ips_file
    fi
}

function main {
    [[ "$CNI_ARGS" == *'K8S_POD_NAMESPACE=default;'* ]] && export DEBUG=true

    exec 3>&1 # make stdout available as fd 3 for the result
    exec &>> /var/log/bash-cni-plugin.log

    stdin=$(cat /dev/stdin)
    debug "stdin: $stdin"

    debug "CNI envs: $(printenv | grep CNI_)"
    # CNI_COMMAND: indicates the desired operation
    case $CNI_COMMAND in
        ADD)
            add
        ;;
        DEL)
            del
        ;;
        GET)
            error "GET not supported"
        ;;
        VERSION)
            echo '{"cniVersion": "0.3.1","supportedVersions": [ "0.3.0", "0.3.1", "0.4.0" ]}' >&3
        ;;
        *)
            echo "Unknown cni command: $CNI_COMMAND"
            exit 1
        ;;
    esac
}

if [[ "${__name__:-"__main__"}" == "__main__" ]]; then
    main
fi
