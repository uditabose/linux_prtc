#!/bin/bash

# filesystem parameters

PART=/dev/sda1
MNTPNT=/mnt/tempdir

# make USB mount dir
if [[ -d "$MNTPNT" ]]; then
	sudo umount "$MNTPNT"
	sudo rm -rf "$MNTPNT"
fi
sudo mkdir -p "$MNTPNT"

# put a filesystem
sudo mkfs.ext4 "$PART"

# mount USB on mountpoint
sudo mount -t ext4 "$PART" "$MNTPNT"

# get fs details
sudo dumpe2fs "$PART" > dumpe2fs-output-initial

# see the details
grep -i -e "Mount count" -e "Check interval" -e "Block Count" dumpe2fs-output-initial

# tune fs, max mounts 30
sudo tune2fs -c 30 "$PART"

# maximum interval for fs check set to 3 weeks
sudo tune2fs -i 3w "$PART"

# reserve a little part of file system 
sudo tune2fs -m 10 "$PART"

# get fs details, again
sudo dumpe2fs "$PART" > dumpe2fs-output-final

# read the details, again
grep -i -e "Mount count" -e "Check interval" -e "Block Count" dumpe2fs-output-final

# see the diff
diff dumpe2fs-output-initial dumpe2fs-output-final