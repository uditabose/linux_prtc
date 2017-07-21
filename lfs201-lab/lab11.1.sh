#!/bin/bash

# the temporary dir
sudo mkdir /mnt/tmpfs
sudo mount -t tmpfs none /mnt/tmpfs

# how much space
df -h /mnt/tmpfs

# can put a size
# sudo mount -t tmpfs -o size=256M none /mnt/tmpfs

sudo umount /mnt/tmpfs

# is /dev/shm mounted
df -h /dev/shm

# does it show
df -h | grep tmpfs
