#!/bin/bash
source os.sh
source colors.sh

HTML_TEMPLATE="index.html.template"
HTML_DIR="/var/www/html/"

# install apache
if [[ $OS == $OS_UBUNTU ]]; then
    sudo apt install -y apache2
    #sudo apt install -y w3m
fi

if [[ $OS == $OS_REDHAT ]]; then
    sudo yum install -y httpd mod_ssl
fi

# copy HTML
cp -v "$HTML_TEMPLATE" "$HTML_DIR/index.html"

# enable apache service

if [[ $OS == $OS_UBUNTU ]]; then
    systemctl enable apache2
    systemctl start apache2
fi

if [[ $OS == $OS_REDHAT ]]; then
    systemctl enable httpd
    systemctl start httpd
fi

