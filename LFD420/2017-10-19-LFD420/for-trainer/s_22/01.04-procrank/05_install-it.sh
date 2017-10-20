#!/bin/bash
HERE=$(pwd)
source ../../env.sh
source ./version.sh
cd ${EXTRA_STUFF}/procrank/procrank_linux
sudo make install
cd ${HERE}
