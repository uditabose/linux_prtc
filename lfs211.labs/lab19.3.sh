#!/bin/bash
source os.sh
source colors.sh
source install.prep.sh

if [[ $OS == $OS_REDHAT ]]; then
    tar xvf myapprpm-1.0.0.tar.gz
    ./myfirstrpm.sh

    myhello
fi