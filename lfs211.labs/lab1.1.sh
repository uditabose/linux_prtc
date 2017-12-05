#!/bin/bash

# if  /etc/sudoers.d directory does not exist, then create
if [[ ! -d '/etc/sudoers.d' ]]; then
    sudo mkdir -p '/etc/sudoers.d'
fi

# add papa to sudoer's file
visudo papa