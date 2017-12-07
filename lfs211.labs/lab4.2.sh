#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    apt intsall postfix
    dpkg-reconfigure postfix
fi

# see smtp
netstat -taupe | grep smtp

# do a telnet on smtp
(
 telnet localhost 25
)

