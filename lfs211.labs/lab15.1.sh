#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

install_pkg telnet-server telnet xinetd

if [[ $OS == $OS_UBUNTU ]]; then
    
    cat >> /etc/xinetd.d/telnet << EOF
service telnet
{
    socket_type = stream
    protocol = tcp
    wait = no
    user = root
    server = /usr/sbin/in.telnetd
}
    EOF

    systemctl restart xinetd
    #telnet localhost
fi

if [[ $OS == $OS_REDHAT ]]; then
    systemctl start telnet.socket
    #telnet localhost
fi

echo "sshd : all" >> /etc/hosts.allow
echo "all : all" >> /etc/hosts.deny

telnet localhost
