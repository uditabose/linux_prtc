#!/bin/bash
HERE=$(pwd)
source ../../env.sh
source ./version.sh
cd ${EXTRA_STUFF}/crash/crash
sudo make install
cd ${HERE}
