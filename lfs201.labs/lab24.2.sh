#!/bin/bash

# fs_mark benchmarking

FSMRK_VER='3.3'
FSMRK='fs_mark'
FSMRK_URL="https://downloads.sourceforge.net/project/fsmark/fsmark/$FSMRK_VER/$FSMRK-$FSMRK_VER.tar.gz"

# download, unarchive, build, install
curl -LO "$FSMRK_URL"
tar -xzvf "$FSMRK-$FSMRK_VER.tar.gz"
cd "$FSMRK"
make

# now run some benchmark
fs_mark -d /tmp -n 1000 -s 10240 &

if [[ ! -x iostat ]]; then
	sudo apt install sar
fi
# get the dits
iostat -x -d /dev/sda 2 20
