#shellcheck shell=bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2022
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

Describe 'plugin.sh'
    Include plugin.sh

    Describe 'allocate_ip()'
        Mock _get_all_ip_list
            ips=""
            for i in {0..7}; do
                ips+="10.244.0.$i\n"
            done
            echo -e "${ips}"
        End
        Mock _get_reserved_ip_list
            ips=""
            for i in {0..2}; do
                ips+="10.244.0.$i\n"
            done
            echo -e "${ips}"
        End
        result(){
            echo -e "10.244.0.1\n10.244.0.3"
        }

        It 'performs IP address allocation'
            When call allocate_ip '10.244.0.0/29'
            The status should be success
            The output should equal "$(result)"
        End
    End
End
