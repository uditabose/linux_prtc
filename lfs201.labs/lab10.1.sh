#!/bin/bash

SDA4=/dev/mmcblk0
#/dev/sda4

# create a partition
sudo fdisk $SDA4

# reboot
sudo reboot now

# format with LUKS for crypt layer
sudo cryptsetup luksFormat  $SDA4
sudo cryptsetup luksOpen $SDA4 secret-disk

# add to crypttab
if [[ -f /etc/crypttab ]]; then
	echo "secret-disk   $SDA4" >> /etc/crypttab
else
	touch /etc/crypttab
	echo "secret-disk   $SDA4" >> /etc/crypttab
fi

# put a file system on new crypt-partition
sudo mkfs -t ext4 /dev/mapper/secret-disk

# make a mount point
sudo mkdir -p /secret

# update fstab
sudo echo "/dev/mapper/secret-disk   /secret   
ext4  defaults 1 2" >> /etc/fstab

# mount that
sudo mount /secret

# mount all, uncomment
sudo mount -a

# reboot again
sudo reboot now







