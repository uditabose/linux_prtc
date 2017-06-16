#!/bin/bash

# ping thrice
ping -c 3 localhost

# how is ICMP
sysctl net.ipv4.icmp_echo_ignore_all

# stop the ping
sudo sysctl net.ipv4.icmp_echo_ignore_all=1

# ping thrice, again
ping -c 3 localhost

# restart the ping
sudo sysctl net.ipv4.icmp_echo_ignore_all=0

# ping thrice, again, alas
ping -c 3 localhost

# do this permanently, won't do it here..., uncomment next 2 lines
# sudo cp /etc/sysctl.conf /etc/sysctl.conf.original
# sudo echo net.ipv4.icmp_echo_ignore_all=0 >> /etc/sysctl.conf
# sysctl -p

# undo permanent
# sudo cp /etc/sysctl.conf /etc/sysctl.conf.noping
# sudo cp /etc/sysctl.conf.original /etc/sysctl.conf