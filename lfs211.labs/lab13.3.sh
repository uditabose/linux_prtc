#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

install_pkg 'samba' 'samba-client' 'samba-common'

SMB_CNF='/etc/samba/smb.conf'
mv "$SMB_CNF" "$SMB_CNF.backup"

SMB_DIR='/home/export/cifs'

cat >> "$SMB_CNF" << EOF
[global]
    workgroup = LNXFND
    server string = Myserver
    log file = /var/log/samba/log.%m
    max log size = 50
    cups options = raw
[mainexports]
    path = /home/export/cifs
    read only = yes
    guest ok = yes
    comment = Main exports share   
EOF

mkdir -p "$SMB_DIR"

if [[ $OS == $OS_UBUNTU ]]; then
    systemctl restart smbd
fi

if [[ $OS == $OS_REDHAT ]]; then
    systemctl restart smb
fi

smbclient -L 127.0.0.1