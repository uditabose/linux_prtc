#!/bin/bash

# stressing the system

STR_PKG='stress-1.0.4'
STR_URL="http://people.seas.harvard.edu/~apw/stress/$STR_PKG.tar.gz"

# download, unarchive, build 
curl -LO $STR_URL
tar -xzvf "$STR_PKG.tar.gz"
cd "$STR_PKG"
./configure
make
sudo make install

# see if installed
stress --help
info stress

# try stressing
# 8 CPU intensive process, each spinning on `sqrt()`
# 4 I/O intensive process, each spinning on `sync()`
# 6 memory intensive process, each spinning on `malloc()`, allocating 256MB 
# run for 20 seconds
stress -c 8 -i 4 -m 6 -t 20s

# merely stress memory
stress -m 4 -t 20s