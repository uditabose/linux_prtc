#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    if [[ ! -f '/etc/network/interface' ]]; then
        echo "$Red Network interface config not found $Color_Off\n"
        exit -1
    fi

    cp '/etc/network/interface' /var/tmp

    cat >> '/etc/network/interface' << EOF
    auto ens160
    iface ens160 inet static
         address 10.0.2.15
         netmask 255.255.255.0
         gateway 10.0.2.2
    dns-nameservers 8.8.8.8
    EOF
fi

if [[ $OS == $OS_REDHAT ]]; then
    if [[ ! -f '/etc/sysconfig/network-scripts/ifcfg-ens192' ]]; then
        echo "$Red Network interface config not found $Color_Off\n"
        exit -1
    fi

    cp '/etc/sysconfig/network-scripts/ifcfg-ens192' /var/tmp

    cat >> '/etc/sysconfig/network-scripts/ifcfg-ens192' << EOF
    DEVICE=ens192
    TYPE=ethernet
    BOOTPROTO=none
    IPADDR=10.0.2.15
    PREFIX=24
    GATEWAY=10.0.2.2
    DNS1=8.8.8.8
    NAME="LFSstatic"
    ONBOOT=yes
    EOF
fi
ifup -a