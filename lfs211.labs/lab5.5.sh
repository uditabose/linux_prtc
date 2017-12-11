#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    sudo apt install -y pssh
    sudo dpkg-query -L pssh | grep bin
fi

if [[ $OS == $OS_REDHAT ]]; then
    sudo yum install -y pssh
    sudo rpm -ql pssh | grep bin
fi

ssh-copy-id 127.0.0.1
echo "127.0.0.1" > ~/ip-list
echo "localhost" >> ~/ip-list
echo "192.168.0.27" >> ~/ip-list