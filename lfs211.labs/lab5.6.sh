#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    sudo apt install -y tightvncserver xtightvncviewer
fi

if [[ $OS == $OS_REDHAT ]]; then
    sudo yum install -y  tigervnc-server tigervnc
fi

vncserver

vncserver localhost:1
