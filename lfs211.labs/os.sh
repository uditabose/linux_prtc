#!/bin/bash

OS="NOT_FOUND"
OS_UBUNTU="UBUNTU"
OS_REDHAT="REDHAT"

# find OS type, ubuntu or redhat
if [[ ! -f '/proc/version' ]]; then
    echo 'No suitable OS found'
    exit -1
fi

if [[ $(grep -ic 'ubuntu' '/proc/version') == 1 ]]; then
    OS=$OS_UBUNTU
fi

if [[ $(grep -ic 'red hat' '/proc/version') == 1 ]]; then
    OS=$OS_REDHAT
fi

if [[ OS == "NOT_FOUND" ]]; then
    echo 'No suitable OS found'
    exit -2
fi