#!/bin/bash

# details in dpkg way

MKFS=mke2fs

# find the package
mkfs_pkg=$(dpkg -S mke2fs | cut -d ':' -f 1 | head -1)

# list all the details of the package
dpkg -L "$mkfs_pkg"

# verify package
dpkg -V "$mkfs_pkg"

# try to remove, but really don't
# dpkg -r "$MKFS"