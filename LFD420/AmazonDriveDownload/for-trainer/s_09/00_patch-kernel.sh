#!/bin/bash

HERE=$(pwd)

source ../env.sh
source ../../common-scripts/common.sh

plus_on
cd  ${STAGING_DIR}/s_02/linux-${KERNEL_VER}

sudo patch --dry-run -p1 < ${HERE}/lab1_syscall_patch
plus_off
plus_echo_green "if everything was OK here let's patch the kernel"
press_enter

plus_on
sudo patch -p1 < ${HERE}/lab1_syscall_patch
plus_off

plus_echo_red "after successful patching go to s_02 and rebuild the kernel"

cd $HERE

