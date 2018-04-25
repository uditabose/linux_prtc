#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

SMB_DIR='/home/export/private/'

mkdir -p "$SMB_DIR"
touch "$SMB_DIR/private_files_only"
 chown -R papa: "$SMB_DIR"

cat >> "$SMB_CNF" << EOF
[private]
    path = /home/export/private
    comment = student’s private share
    read only = No
    public = No
    valid users = papa   
EOF

smbpasswd -a papa
smbclient -U papa //SERVER/private

echo "username=papa" > /root/smbfile
echo "password=papa" >> /root/smbfile
chmod 600 /root/smbfile
