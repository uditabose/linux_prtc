#!/bin/bash

# create a partition on a very fat file

IMG_FILE=imagefile
MNT=mntpnt
FILE=test
LINE='this line is lala'
# craete the fat file with all zeros
dd if=/dev/zero of="$IMG_FILE" bs=1M count=1024

# put a filesystem on it
mkfs.ext4 "$IMG_FILE"

# create a mount point
mkdir "$MNT"

# mount it
sudo mount -o loop "$IMG_FILE" "$MNT"

# alternative loop mount
# sudo losetup /dev/loop2 imagefile
# sudo mount /dev/loop2 mntpoint


# write a file
sudo touch "$MNT/$FILE"
ls -l "$MNT/$FILE"
sudo echo "$LINE" >> "$MNT/$FILE"

# test the file
if [[ ! -f "$MNT/$FILE" ]]; then
	echo "failed!"
else 
	if [[ "$LINE" == $(sudo cat "$MNT/$FILE") 	]];then
		echo "didn't write to file"
	fi
fi

# unmount
to_umount=${1:-'y'}
if [[ $to_umount == 'y' ]]; then
  sudo umount "$MNT"
fi
# cleanly
# sudo losetup -d /dev/loop2
