#!/bin/bash

# associate loop device
first_loop=$(sudo losetup -f)
echo $first_loop

# attach  loop
sudo losetup $first_loop imagefile

# which loops are used
losetup -a

# create a partition label
sudo parted -s $first_loop mklabel msdos

# create 3 primary loop devices
sudo parted -s $first_loop unit MB mkpart primary ext4 0 256
sudo parted -s $first_loop unit MB mkpart primary ext4 256 512
sudo parted -s $first_loop unit MB mkpart primary ext4 512 1024

# check partition table
fdisk -l $first_loop

# check sub-partitions
ls -l $first_loop*

# put a file system
sudo mkfs.ext3 "$first_loop"p1
sudo mkfs.ext4 "$first_loop"p2
sudo mkfs.vfat "$first_loop"p3

# create mount points 
mkdir mnt1 mnt2 mnt3

# mount
sudo mount "$first_loop"p1 mnt1
sudo mount "$first_loop"p2 mnt2
sudo mount "$first_loop"p3 mnt3

# test mount points
df -Th

# unmount, clean up
sudo umount mnt1 mnt2 mnt3
rmdir mnt1 mnt2 mnt3
sudo losetup -d "$first_loop"
