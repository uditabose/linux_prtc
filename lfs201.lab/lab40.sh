#!/bin/bash

# firewall

# is there
which firewalld firewall-cmd

if [[ ! -x firewalld ]]; then
	sudo apt install firewalld
fi

# firewall : examination

firewall-cmd --help

# add services, add --permanent for permanent services
sudo firewall-cmd --zone=public --add-service=http
sudo firewall-cmd --zone=public --add-service=https

# list it
sudo firewall-cmd --list-services --zone=public

# reload
sudo firewall-cmd --reload

# list it
sudo firewall-cmd --list-services --zone=public