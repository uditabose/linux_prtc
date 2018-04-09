#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    sudo apt install -y nmap iptraf
fi

if [[ $OS == $OS_REDHAT ]]; then
    sudo yum install -y nmap iptraf
fi
