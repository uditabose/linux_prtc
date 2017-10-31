#!/bin/bash

IMG_FILE=imagefile
MNT=mntpnt

# test if mount point is there
if [[ $(sudo mount | grep -c mntpnt) == 0 ]];then
	./lab9.1.sh 'n'
fi

# run fdisk
 
sudo fdisk -C 130 "$IMG_FILE"

# type `m`

# create new partition
# type `n`

# select primary partition
# type `p`

# write partition table to dist
# type `w`

