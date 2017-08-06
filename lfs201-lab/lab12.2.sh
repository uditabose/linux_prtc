#!/bin/bash

# mounting options


IMG_FILE=imagefile
PART=/dev/mmcblk0
MNTPNT=/mnt/tempdir

# create a fat file if not there
if [[ -f "$IMG_FILE" ]]; then
	rm -f "$IMG_FILE"
fi

# create mount point
sudo mkdir -p "$MNTPNT"

# create a fat file
dd if=/dev/zero of="$IMG_FILE" bs=1M count=256

# mount the fat file
sudo mount -o rw "$IMG_FILE" "$MNTPNT"

# put a file system
sudo mkfs -t ext4 -v "$IMG_FILE"

# create a new partition
echo -e "n\np\n\n+256Mw" | fdisk "$IMG_FILE"
sudo partprobe -s

# create a file
sudo touch "$MNTPNT/afile"

# unmount
sudo umount "$MNTPNT"