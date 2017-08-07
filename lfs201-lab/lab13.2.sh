#!/bin/bash

# managing fs quota

PART=/dev/sda1
PART_NEW=/dev/sda2
MNTPNT=/mnt/tempdir
MNT_NEW=/mnt/tempdir2
IMG_FILE="$MNTPNT/imagefile"
FSTAB=/etc/fstab

# make USB mount dir
if [[ -d "$MNTPNT" ]]; then
	sudo rm -rf "$MNTPNT"
fi
sudo mkdir -p "$MNTPNT"

# mount USB partition 
sudo mount "$PART" "$MNTPNT"

# delete a fat file if there
if [[ -f "$IMG_FILE" ]]; then
	sudo rm -f "$IMG_FILE"
fi

# create a fat file
sudo dd if=/dev/zero of="$IMG_FILE" bs=1M count=1024 

# make a partition
echo -e "n\np\n2\n+512w" | fdisk "$IMG_FILE"

# put a file system
sudo mkfs -t ext4 -v "$IMG_FILE"

# make mount dir
if [[ -d "$MNT_NEW" ]]; then
	sudo rm -rf "$MNT_NEW"
fi
sudo mkdir -p "$MNT_NEW"

# mount partition 
sudo mount "$IMG_FILE" "$MNT_NEW"

# update fstab
sudo su root -c "echo $PART_NEW $MNT_NEW ext4 usrquota 1 2 >> $FSTAB"
sudo su root -c "echo $IMG_FILE $MNT_NEW ext4 loop,usrquota 1 2 >> $FSTAB"

# remount 
sudo mount -o remount "$MNTPNT"

# check for quota
sudo quotacheck -u "$MNTPNT"
sudo quotaon -u "$MNTPNT"

# try to create big files on mountpoint
sudo chown pi:pi -Rv "$MNTPNT"
cd "$MNTPNT"
dd if=/dev/zero of=big1 bs=1024 count=200
dd if=/dev/zero of=big2 bs=1024 count=400

# test quota
quota

# make more big file
dd if=/dev/zero of=big3 bs=1024 count=600

# test quota, again
quota

# view files
ls -lh

