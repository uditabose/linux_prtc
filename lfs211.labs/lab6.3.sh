#!/bin/bash
source os.sh
source colors.sh

NAMED_FILE=""
ZONE_FILE=""
if [[ $OS == $OS_UBUNTU ]]; then
    NAMED_FILE='/etc/bind/named.conf.local'
    ZONE_FILE='/etc/bind/45.25.10.in-addr.arpa.zone'
    EX_ZONE='zone "45.25.10.in-addr.arpa." IN { \
                type master;
                file "/etc/bind/45.25.10.in-addr.arpa.zone";
            };'

    echo "$EX_ZONE" >> "$NAMED_FILE"
fi

if [[ $OS == $OS_REDHAT ]]; then
    NAMED_FILE='/etc/named.conf'
    ZONE_FILE='/var/named/45.25.10.in-addr.arpa.zone'
    EX_ZONE='zone "45.25.10.in-addr.arpa." IN { \
                type master;
                file "45.25.10.in-addr.arpa.zone";
            };'

    echo "$EX_ZONE" >> "$NAMED_FILE"
fi

if [[ ! -f "$ZONE_FILE" ]]; then
    touch "$ZONE_FILE"
fi

echo '$TTL 30' >> "$ZONE_FILE"
echo '@ IN SOA  localhost. admin.example.com. (' >> "$ZONE_FILE"
echo '2012092901 ; serial YYYYMMDDRR format' >> "$ZONE_FILE"
echo '3H         ; refresh' >> "$ZONE_FILE"
echo '1H         ; retry' >> "$ZONE_FILE"
echo '2H         ; expire' >> "$ZONE_FILE"
echo '1M)        ; neg ttl' >> "$ZONE_FILE"
echo '@ IN NS localhost.;' >> "$ZONE_FILE"
echo ';generate 1-254' >> "$ZONE_FILE"
echo '$GENERATE 1-254 $  IN PTR host$.example.com.' >> "$ZONE_FILE"

# test named config
named-checkzone

# reload named daemon
sudo rndc reload

# test DNS entries
host 10.20.45.7 localhost
host 10.20.45.37 localhost
host 10.20.45.73 localhost