#!/bin/bash

# secure mounting options

MNTPNT=/mnt/tempdir
IMG_FILE=imagefile
LS='/bin/ls'

# delete, create fat file
rm -f "$IMG_FILE"
dd if=/dev/zero of="$IMG_FILE" bs=1M count=100

# put a filesystem
sudo mkfs.ext3 "$IMG_FILE"

# mount normally
sudo rm -rf "$MNTPNT"
sudo mkdir -p "$MNTPNT"
sudo mount -o loop "$IMG_FILE" "$MNTPNT"

# copy executable file, run that
sudo cp "$LS" "$MNTPNT"
sudo "$MNTPNT/ls -lh"

# unmount, mount with noexec, run
sudo umount "$MNTPNT"
sudo mount -o noexec,loop "$IMG_FILE" "$MNTPNT"
sudo "$MNTPNT/ls -lh"

# or remount
# sudo mount -o noexec,remount "$IMG_FILE" "$MNTPNT"

# unmount, clean
sudo umount "$MNTPNT"
sudo rm -rf "$IMG_FILE"
sudo rm -rf "$MNTPNT"