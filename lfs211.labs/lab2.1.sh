#!/bin/bash
source os.sh

if [[ $OS == $OS_UBUNTU ]]; then
    sudo apt -y install vsftpd ftp
fi

if [[ $OS == $OS_REDHAT ]]; then
    sudo yum install -y vsftpd ftp
fi