#!/bin/bash
source os.sh
source colors.sh

# show ip address
ip address show

# show default network route
ip route show

# default nameserver
cat /etc/resolv.conf
