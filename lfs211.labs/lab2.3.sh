#!/bin/bash
source os.sh
source colors.sh

# start vfstpd via SysV init script if available
if [[ -f '/etc/init.d/vsftpd' ]]; then
    '/etc/init.d/vsftpd' start
else
    echo -ne "$Red SysV init scripts not available $Color_Off\n"
fi

# test if the service is up
if [[ $(ps -ef | grep -c 'vsftpd') == 1 ]]; then
    echo -ne "$Yellow FTP service is running $Color_Off\n"
fi

# use service
ftp localhost

# stop the daemon
if [[ -f '/etc/init.d/vsftpd' ]]; then
    '/etc/init.d/vsftpd' stop
else
    echo -ne "$Red SysV init scripts not available $Color_Off\n"
fi