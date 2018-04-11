#!/bin/bash
source os.sh
source colors.sh

# add IP address
VHOST_IP=""
NET_INTF=""
VHOST_FILE=""
if [[ $OS == $OS_UBUNTU ]]; then
    VHOST_IP="192.168.153.10"
    NET_INTF="ens160"
    VHOST_FILE="/etc/apache2/sites-enabled/ipvhost.conf" 
fi

if [[ $OS == $OS_REDHAT ]]; then
    VHOST_IP="192.168.153.20"
    NET_INTF="ens192"
    VHOST_FILE="/etc/httpd/conf.d/ipvhost.conf"
    
fi
ip addr add "$VHOST_IP"/24 dev "$NET_INTF"
sudo mkdir /ipvhost/

chcon -R --reference='/var/www/html' '/ipvhost/'

vhost_det="<VirtualHost $VHOST_IP:80>\
     DocumentRoot /ipvhost/ \
     ServerName ipvhost.example.com \
     <Directory /ipvhost/> \
       Options Indexes FollowSymLinks \
       AllowOverride None \
       Require all granted \
     </Directory> \
 </VirtualHost>"

touch "$VHOST_FILE"
echo "$vhost_det" >> "$VHOST_FILE"

# enable apache service

if [[ $OS == $OS_UBUNTU ]]; then
    systemctl enable apache2
    systemctl start apache2
fi

if [[ $OS == $OS_REDHAT ]]; then
    systemctl enable httpd
    systemctl start httpd
fi

