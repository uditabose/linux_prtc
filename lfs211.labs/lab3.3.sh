#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    ip addr add 10.200.45.100/24 dev ens160
fi

if [[ $OS == $OS_REDHAT ]]; then
    ip addr add 10.200.45.110/24 dev ens192
fi

if [[ $OS == $OS_UBUNTU ]]; then
    ping -c 3 10.200.45.110
fi

if [[ $OS == $OS_REDHAT ]]; then
    ping -c 3 10.200.45.100
fi
