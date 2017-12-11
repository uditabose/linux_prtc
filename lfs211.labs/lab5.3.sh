#!/bin/bash
source os.sh
source colors.sh

# enable password-less 
if [[ $(grep -c 'PermitRootLogin without-password' '/etc/ssh/sshd_config') -eq 0 ]]; then
    echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config
fi

if [[ $OS == $OS_UBUNTU ]]; then
    systemctl restart ssh
fi

if [[ $OS == $OS_REDHAT ]]; then
    systemctl restart sshd.service
fi

if `ssh -x playground`; then
    echo "$Cyan All good then! $Color_Off"
else
    cat /home/papa/.ssh/authorized_keys >> /root/.ssh/authorized_keys
    chown root:root /root/.ssh/authorized_keys
    chmod 640 /root/.ssh/authorized_keys
fi

ssh playground "hostname && id"




