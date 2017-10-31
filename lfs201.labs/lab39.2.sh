#!/bin/bash

# networking : hostname

# update the hosts
sudo sh -c "echo 192.168.1.180 mysystem.mydomain >> /etc/hosts"

# ping it
ping mysystem.mydomain

# add more
sudo sh -c "echo 127.0.0.1 ad.doubleclick.net >> /etc/hosts"
ping ad.doubleclick.net

# wget
wget http://winhelp2002.mvps.org/hosts.txt
cat hosts.txt