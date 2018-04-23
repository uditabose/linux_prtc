#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

install_pkg ntp
NTP_CONF='/etc/ntp.conf'
if [[ -f $NTP_CONF ]]; then
    echo 'server 0.pool.ntp.org' >> $NTP_CONF
    echo 'server 1.pool.ntp.org' >> $NTP_CONF
    echo 'server 2.pool.ntp.org' >> $NTP_CONF
    echo 'server 3.pool.ntp.org' >> $NTP_CONF
fi

if [[ $OS == $OS_UBUNTU ]]; then
    systemctl restart ntp
fi

if [[ $OS == $OS_REDHAT ]]; then
    systemctl restart ntpd
fi

ntp -q