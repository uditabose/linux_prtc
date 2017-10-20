#!/bin/bash
source ../../env.sh
source ../../../common-scripts/common.sh
#plus_echo "sudo crash ${KROOT}/vmlinux"
plus_echo "vmtouch -vf /bin/"
press_enter
#sudo crash ${KROOT}/vmlinux
vmtouch -vf /bin/
