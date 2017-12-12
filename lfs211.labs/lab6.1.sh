#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    sudo apt install -y bind9 bind9utils dig
    sudo systemctl restart bind9.service
    dig google.com

fi

if [[ $OS == $OS_REDHAT ]]; then
    sudo yum install -y bind-utils
    sudo systemctl restart named.service

    dig @localhost google.com
    dig @127.0.0.1 google.com
fi


