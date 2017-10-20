#!/bin/bash
HERE=$(pwd)
source ../../env.sh
source ./version.sh
cd ${EXTRA_STUFF}/vmtouch/vmtouch
sudo make install
cd ${HERE}
