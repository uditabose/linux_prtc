#!/bin/bash
source os.sh
source colors.sh

# start vfstpd via systemctl
systemctl start vsftpd.service

# test if the service is up
if [[ $(ps -ef | grep -c 'vsftpd') == 1 ]]; then
    echo -ne "$Yellow FTP service is running $Color_Off\n"
fi

# see system status
systemctl status vsftpd.service

# use service
ftp localhost

# stop service 
systemctl stop vsftpd.service