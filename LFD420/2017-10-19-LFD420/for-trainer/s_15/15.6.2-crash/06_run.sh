#!/bin/bash
source ../../env.sh
source ../../../common-scripts/common.sh
plus_echo "sudo crash ${KROOT}/vmlinux"
press_enter
sudo crash ${KROOT}/vmlinux
