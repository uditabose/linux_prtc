#!/bin/bash
source os.sh
source colors.sh

ZONE_FILE=""
if [[ $OS == $OS_UBUNTU ]]; then
    EX_ZONE='zone "example.com." IN { \
                type master; \
                file "example.com.zone"; \
            };'

    echo "$EX_ZONE"
    sudo echo "$EX_ZONE" >> /etc/bind/named.conf.local
    ZONE_FILE="/etc/bind/example.zone"

fi

if [[ $OS == $OS_REDHAT ]]; then
    EX_ZONE='zone "example.com." IN { \
                type master; \
                file "/etc/bind/example.com.zone"; \
            };'

    echo "$EX_ZONE"
    sudo echo "$EX_ZONE" >> /etc/named.conf
    ZONE_FILE="/var/named/example.zone"
fi

sudo touch "$ZONE_FILE"
sudo echo "$TTL 30" >> "$ZONE_FILE"
sudo echo "@ IN SOA localhost. admin.example.com. (" >> "$ZONE_FILE"
sudo echo "2012092901 ; serial YYYYMMDDRR format" >> "$ZONE_FILE"
sudo echo "3H ; refresh" >> "$ZONE_FILE"
sudo echo "1H ; retry" >> "$ZONE_FILE"
sudo echo "2H ; expire" >> "$ZONE_FILE"
sudo echo "1M) ; neg ttl" >> "$ZONE_FILE"
sudo echo "IN NS localhost.;" >> "$ZONE_FILE"
sudo echo "www.example.com. IN A 192.168.111.45" >> "$ZONE_FILE"
sudo echo "www.example.com. IN AAAA fe80::22c9:d0ff:1ecd:c0ef" >> "$ZONE_FILE"
sudo echo "foo.example.com. IN A 192.168.121.11" >> "$ZONE_FILE"
sudo echo "bar.example.com. IN CNAME www.example.com." >> "$ZONE_FILE"
sudo echo ";generate one hundred entries host1 thru host100" >> "$ZONE_FILE"
sudo echo "$GENERATE 1-100 host$.example.com. IN A 10.20.45.$" >> "$ZONE_FILE"

if [[ $OS == $OS_UBUNTU ]]; then
    sudo systemctl restart bind9.service
    
    dig -t A www.example.com
    dig -t AAAA www.example.com
    dig -t A foo.example.com
    dig -t CNAME bar.example.com
    dig -t A host7.example.com
    dig -t A host37.example.com

fi

if [[ $OS == $OS_REDHAT ]]; then
    sudo systemctl restart named.service

    dig @localhost -t A www.example.com
    dig @localhost -t AAAA www.example.com
    dig @localhost -t A foo.example.com
    dig @localhost -t CNAME bar.example.com
    dig @localhost -t A host7.example.com
    dig @localhost -t A host37.example.com
fi
