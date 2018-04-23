#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    INTF_FILE='/etc/network/interfaces'
    INTF='ens160'
    cat >> "$INTF_FILE" << EOF
    auto "$INTF".7
    iface "$INTF".7 inet static
        address 192.168.20.100
        netmask 255.255.255.0
        vlan-raw-device "$INTF"
    EOF

    ifup $INTF.7
fi

if [[ $OS == $OS_REDHAT ]]; then
    if [[ -f '/etc/sysconfig/network' ]]; then
        echo 'VLAN=yes' >> /etc/sysconfig/network
        echo 'VLAN_NAME_TYPE="DEV_PLUS_VID"' >> /etc/sysconfig/network
    fi

    INTF='ens192'
    INTF_FILE="/etc/sysconfig/network-scripts/ifcfg-$INTF.7"

    touch "$INTF"
    cat >> "$INTF_FILE" <<EOF
        DEVICE=$INTF.7
        BOOTPROTO=static
        TYPE=vlan
        ONBOOT=yes
        IPADDR=192.168.30.100
        NETMASK=255.255.255.0
        PHYSDEV="$INTF"
    
    EOF

    ifup $INTF.7 
fi