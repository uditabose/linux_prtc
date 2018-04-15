#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

# install package 
install_pkg "postfix"

# enable postfix on all interfaces
postconf -e "inet_interfaces = all"

# enable subnet
postconf -e "mynetworks_style = subnet"

# restart postfix
systemctl restart postfix

# test
telnet 127.0.0.1 25

