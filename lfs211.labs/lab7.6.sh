#!/bin/bash
source os.sh
source colors.sh

if [[ $OS == $OS_UBUNTU ]]; then
    /usr/bin/openssl genrsa -aes128 2048 > /etc/ssl/private/server.key
    /usr/bin/openssl req -utf8 -new -key \
        -key /etc/pki/tls/private/ipvhost.example.com.key \
        -out /etc/pki/tls/certs/ipvhost.example.com.csr
fi

if [[ $OS == $OS_REDHAT ]]; then
    /usr/bin/openssl genrsa -aes128 2048 > /etc/pki/tls/private/ipvhost.example.com.key
    /usr/bin/openssl req -utf8 -new \
        -key /etc/ssl/private/server.key \
        -out /etc/ssl/server.csr    
fi
