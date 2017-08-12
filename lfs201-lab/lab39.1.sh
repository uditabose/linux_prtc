#!/bin/bash

# networking basic

# show it
ip addr show eth0
ip route
cp /etc/resolv.conf resolv.conf.keep

ifconfig eth0
route -n

# down the eth0
sudo ip link set eth0 down

# up the eth0
sudo ip link set eth0 up

# down the eth0
sudo ifconfig eth0 down

# up the eth0
sudo ifconfig eth0 up

# see that
cat /etc/sysconfig/network