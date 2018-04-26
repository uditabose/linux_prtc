#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

install_pkg keyutils-libs-devel libattr-devel
install_pkg libkeyutils-dev libattr1-dev

git clone -v git://kernel.ubuntu.com/cking/stress-ng.git

cd stress-ng
make

./stress-ng -c 3 -t 10s -m 4

sudo make install

cd /tmp
stress-ng -c 3 -t 10s -m 4
man stress-ng
