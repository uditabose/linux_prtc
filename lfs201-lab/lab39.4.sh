#!/bin/bash

# networking : add a static route

# see the route
route
ip route

# add a route
sudo nmcli con mod "$CON" +ipv4.routes "192.168.100.0/24 172.16.2.1"

# route has not taken effect
route

# update
sudo nmcli con up "$CON"

# see it
route

# delete it 
sudo nmcli con mod "$CON" -ipv4.routes "192.168.100.0/24 172.16.2.1"

# re-up
sudo nmcli con up "$CON"

# see it
route