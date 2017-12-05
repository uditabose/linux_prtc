#!/bin/bash
source os.sh
#source ../colors.sh

#echo -ne $Green"$dir : git comment :: "$Color_Off

# see the status
systemctl status vsftpd.service

# stop the service
systemctl stop vsftpd.service

# start daemon manually
if [[ $OS == $OS_UBUNTU ]]; then
    /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf &
fi

if [[ $OS == $OS_REDHAT ]]; then
    /usr/sbin/vsftpd /etc/vsftpd.conf &
fi

# verify service is running
ps -ef | grep vsftpd

# use the service
ftp localhost

# stop daemon 
killall vsftpd

