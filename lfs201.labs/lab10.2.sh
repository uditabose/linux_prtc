#!/bin/bash

# is there a swap
cat /proc/swaps

# switch off swap
sudo swapoff /var/swap 
# this unusualpath for linux, but it's a pi 
# afterall

# setup luks on swap
sudo cryptsetup luksFormat /var/swap
sudo cryptsetup luksOpen  /var/swap swapcrypt

# make the swap
sudo mkswap /dev/mapper/swapcrypt

# has it worked ?
sudo swapon /dev/mapper/swapcrypt
cat /proc/swaps
