#!/bin/bash
#sudo apt-get remove crash
#sudo apt-get install texinfo bison

HERE=$(pwd)
#set -x
source ../../env.sh
source ./version.sh
cd ${EXTRA_STUFF}/vmtouch/vmtouch
make
#set +x
cd ${HERE}
