#!/bin/bash 

MOD_ROSE=/lib/modules/$(uname -r)/kernel/drivers/net/dummy.ko


# list all modules
lsmod

echo
echo "**********************"
echo

# load module
if [[ -f "$MOD_ROSE" ]]; then
	sudo insmod "$MOD_ROSE"
	# the other way
	# sudo /sbin/modprobe "$MOD_ROSE"
else 
	echo "no such modules"
fi

# test if the module is really loaded
has_mod=$(lsmod | grep -c 'dummy')

if [[ $has_mod -gt 0 ]]; then
	echo "oh man! it's loaded"
else 
	echo "darn!"
fi

# unload modules, rally won't do it, but anyway
# sudo rmmod dummy
# or
# sudo modprobe -r dummy

# re-test


