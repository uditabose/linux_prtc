#!/bin/bash

# managing swap space

SWP_FILE=swap_file
SWPS=/proc/swaps

# delete a fat file if there
if [[ -f "$SWP_FILE" ]]; then
	rm -f "$SWP_FILE"
fi

# create a fat file
dd if=/dev/zero of="$SWP_FILE" bs=1M count=512

# switch on the swap
sudo chown root:root "$SWP_FILE"
sudo chmod 600 "$SWP_FILE"

# make a swap file
sudo mkswap "$SWP_FILE"
sudo swapon "$SWP_FILE"

# view the swaps
cat "$SWPS"

# switch off, clean up
sudo swapoff "$SWP_FILE"
rm -f "$SWP_FILE"