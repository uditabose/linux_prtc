#!/bin/bash
MODULE_NAME=my_debugfs

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

${SUDO} mount -t debugfs none /sys/kernel/debug

if [ ! -d /lib/modules/`uname -r`/kernel/drivers/ ];
then
    echo "creating dir!"
    ${SUDO} mkdir -p /lib/modules/`uname -r`/kernel/drivers/
fi

${SUDO} cp $MODULE_NAME.ko /lib/modules/`uname -r`/kernel/drivers/
${SUDO} depmod
${SUDO} modprobe $MODULE_NAME

${SUDO} opcontrol --init 
${SUDO} opcontrol --vmlinux=/home/rber/projects/LF/LF320/SOLUTIONS/s_07/linux-2.6/vmlinux 
${SUDO} opcontrol --reset 
${SUDO} opcontrol -l
${SUDO} opcontrol --start-daemon
${SUDO} opcontrol --verbose --start 

${SUDO} cat /sys/kernel/debug/mydir/filen

sleep 5

${SUDO} opcontrol --dump 
${SUDO} opcontrol --stop  
${SUDO} opreport --image-path /lib/modules/`uname -r`/kernel
${SUDO} opreport --image-path /lib/modules/`uname -r`/kernel -l vmlinux
# try this:
# Run opreport with " -p /lib/modules/`uname -r` ".

#opreport -lc --image-path /lib/modules/`uname -r`/kernel

${SUDO} modprobe -r $MODULE_NAME
${SUDO} rm -f /lib/modules/`uname -r`/kernel/drivers/$MODULE_NAME.ko
