#!/bin/bash
#/* **************** LFD420:4.13 s_08/DO_KERNEL.sh **************** */
#/*
# * The code herein is: Copyright the Linux Foundation, 2017
# *
# * This Copyright is retained for the purpose of protecting free
# * redistribution of source.
# *
# *     URL:    http://training.linuxfoundation.org
# *     email:  trainingquestions@linuxfoundation.org
# *
# * This code is distributed under Version 2 of the GNU General Public
# * License, which you should have received with the source.
# *
# */
#!/bin/bash

# Script to compile and install the Linux kernel and modules.
# written by Jerry Cooperstein (2002-2017)
# Copyright GPL blah blah blah

# determine which distribution we are on
get_SYSTEM(){
    [[ -n $SYSTEM ]] && return
    SYSTEM=
    [[ -n $(grep -i Red\ Hat /proc/version) ]] && SYSTEM=REDHAT && return
    [[ -n $(grep -i Ubuntu   /proc/version) ]] && SYSTEM=UBUNTU && return
    [[ -n $(grep -i debian   /proc/version) ]] && SYSTEM=DEBIAN && return
    [[ -n $(grep -i suse     /proc/version) ]] && SYSTEM=SUSE   && return
    [[ -n $(grep -i gentoo   /proc/version) ]] && SYSTEM=GENTOO && return
}

# find out what kernel version this is
get_KERNELVERSION(){
    for FIELD in VERSION PATCHLEVEL SUBLEVEL EXTRAVERSION ; do
	eval $(sed -ne "/^$FIELD/s/ //gp" Makefile)
    done
# is there a local version file?
    for lvfile in ./localversion-* ; do 
	EXTRAVERSION="$EXTRAVERSION$(cat $lvfile)"
    done
    KERNEL=$VERSION.$PATCHLEVEL.$SUBLEVEL$EXTRAVERSION
}

# parallelize, speed up for multiple CPU's
get_MAKE(){
    NCPUS=$(grep ^processor /proc/cpuinfo | wc -l)
    JOBS=$(( 3*($NCPUS-1)/2 + 2 ))
    MAKE="make -j $JOBS"
}

make_initramfs(){
    case "$SYSTEM" in 
	"REDHAT")
	    dracut -v -f $BOOT/initramfs-$KERNEL.img $KERNEL

# Update /boot/grub/grub.conf or /boot/grub2/grub.cfg
# RHEL6 has grub1, FC17 and later has grub2
	    [[ -f /boot/grub/grub.conf ]] \
		&& cp /boot/grub/grub.conf /boot/grub/grub.conf.BACKUP
	    [[ -f /boot/grub2/grub.cfg ]] \
		&& cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.BACKUP
	    /sbin/grubby --copy-default  \
		--make-default \
		--remove-kernel=$BOOT/vmlinuz-$KERNEL \
		--add-kernel=$BOOT/vmlinuz-$KERNEL \
		--initrd=$BOOT/initramfs-$KERNEL.img \
		--title=$BOOT/$KERNEL
	    ;;
	"DEBIAN" | "UBUNTU" )
	    make install
	    update-initramfs -ct -k $KERNEL
	    update-grub
	    ;;
	"SUSE")
	    make install
	    ;;
	"GENTOO")
	    make install
	    genkernel 	ramdisk --kerneldir=$PWD   
	    ;;
	*)
	    echo System $SYSTEM is not something I understand, can not make initramfs
	    exit
	    ;;
    esac
}

##########################################################################
# Start of the work

BOOT=/boot
get_KERNELVERSION
get_SYSTEM
get_MAKE

echo building: Linux $KERNEL kernel,  and placing in: $BOOT on a $SYSTEM system

# set shell to abort on any failure and echo commands
set -e -x

# Do the main compilation work, kernel and modules
$MAKE

# Install the modules
$MAKE modules_install 

# Install the compressed kernel, System.map file, config file, 
cp arch/x86/boot/bzImage   $BOOT/vmlinuz-$KERNEL 
cp System.map              $BOOT/System.map-$KERNEL 
cp .config                 $BOOT/config-$KERNEL 

# Install also the uncompressed kernel for later reference during debugging
[ -f vmlinux ] && cp vmlinux $BOOT/vmlinux-$KERNEL

# making initramfs and updating grub is very distribution dependendent:
echo I am building the initramfs image and modifying grub config on $SYSTEM
make_initramfs "$SYSTEM"
