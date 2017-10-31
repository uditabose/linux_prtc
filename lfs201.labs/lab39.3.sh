#!/bin/bash

# networking : nmcli

# see the connection
CON='Wired connection 1'
sudo nmcli con

sudo nmcli con show "$CON" | grep IP4.ADDRESS

# update
sudo nmcli con modify "$CON" +ipv4.addresses 172.16.2.140/24

# activate
sudo nmcli con up "$CON"

# ping 
ping -c 3 172.16.2.140

# clean up
sudo nmcli con modify "$CON" -ipv4.addresses 172.16.2.140/24

# activate
sudo nmcli con up "$CON"