#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# error() - This function prints an error message in the standard output
function error {
    _print_msg "ERROR" "$1"
    exit 1
}

# info() - This function prints an information message in the standard output
function info {
    _print_msg "INFO" "$1"
}

function _print_msg {
    printf "\n%s - %s: %s\n" "$(date +%H:%M:%S)" "$1" "$2"
}
