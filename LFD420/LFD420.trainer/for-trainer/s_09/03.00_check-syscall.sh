#!/bin/bash

source ../../common-scripts/common.sh

plus_on
cat /lib/modules/$(uname -r)/build/arch/x86/include/generated/uapi/asm/unistd_64.h
plus_off

plus_echo "Is your syscall there?"
