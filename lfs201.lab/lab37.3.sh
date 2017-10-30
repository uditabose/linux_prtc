#!/bin/bash

# rsync-ing

rm -rfv include

# rsync
rsync -av /usr/include .

# see what has happened
rsync -av /usr/include .

# what happens?
rsync -av --delete /usr/include .

# what happens when child dirs are deleted
rm -rf include/xen

# resync
rsync -av --delete --dry-run /usr/include .

# see what's going on
rsync -av --delete /usr/include .