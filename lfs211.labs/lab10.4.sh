#!/bin/bash
source os.sh
source colors.sh

mkdir '/srv/rsync/'
for i in '/srv/rsync/{a,b,c}-{1,2,3}.{txt,log,bin}'; do
    echo $i > $i
done

if [[ ! -f '/etc/rsyncd.conf' ]]; then
    touch '/etc/rsyncd.conf'
fi

echo "[default]" >> '/etc/rsyncd.conf'
echo "   path = /srv/rsync" >> '/etc/rsyncd.conf'
echo "   comment = default rsync files" >> '/etc/rsyncd.conf'

if [[ $OS == $OS_REDHAT ]]; then
    systemctl start rsyncd
    systemctl enable rsyncd
fi

if [[ $OS == $OS_UBUNTU ]]; then
    update-rc.d rsync enable 2345
    echo "RSYNC_ENABLE=true" >> /etc/default/rsync
    systemctl start rsync
fi

rsync localhost