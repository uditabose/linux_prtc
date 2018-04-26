#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

install_pkg  dh-make fakeroot build-essential

if [[ $OS == $OS_UBUNTU ]]; then
    tar xvf 'myappdebian-1.0.tar.gz'
    rm -rf WORK && mkdir WORK && cd WORK

    cd myappdebian-1.0
    dh_make -f ../*myappdebian-1.0.tar.gz
    dpkg-buildpackage -uc -us

    ./myhello

    dpkg --contents ../*.deb

    cd ..
    sudo dpkg --install *.deb

    myhello

    sudo dpkg --remove myappdebian
fi

