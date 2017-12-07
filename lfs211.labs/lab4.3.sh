#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    cp '/etc/vsftpd.conf' '/etc/vsftpd.conf.orig'
    echo 'tcp_wrappers=yes' >> '/etc/vsftpd.conf'
fi

# start vsftpd
/etc/init.d/vsftpd start

# check port
telnet localhost ftp

# block port
if [[ -f '/etc/hosts.deny' ]]; then
    cp '/etc/hosts.deny' '/etc/hosts.deny.orig'
    echo 'vsftpd: ALL' >> '/etc/hosts.deny'
fi

# iptables
iptables -A INPUT -m tcp -p tcp --dport ftp -j REJECT

# check port to prove it's blocked
telnet localhost ftp

# restore back
if [[ $OS == $OS_UBUNTU ]]; then
    rm -f '/etc/vsftpd.conf' 
    mv '/etc/vsftpd.conf.orig' '/etc/vsftpd.conf'
fi

if [[ -f '/etc/hosts.deny.orig' ]]; then
    rm -f '/etc/hosts.deny'
    mv '/etc/hosts.deny.orig' '/etc/hosts.deny'
fi

iptables -F

