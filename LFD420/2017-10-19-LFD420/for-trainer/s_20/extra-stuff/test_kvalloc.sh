#!/bin/bash
# test_kvalloc.sh [start_numbytes] [step_factor]

if [ $# -lt 1 ]; then
	echo "Usage: $(basename $0) {k|v} [start_numbytes] [step_factor]"
	echo " k : test the KMALLOC limit"
	echo " v : test the VMALLOC limit"
	exit 1
fi

[ $1 != "k" -a $1 != "v" ] && {
	echo "$0: invalid choice '$1' (should be either 'k' or 'v')"
	exit 1
}
#[ $1 = "k" ] && KVALLOC_PROCFILE=/proc/driver/kmalloc_test
#[ $1 = "v" ] && KVALLOC_PROCFILE=/proc/driver/vmalloc_test
[ $1 = "k" ] && KVALLOC_DEVFS_FILE=/dev/kmalloc_test
[ $1 = "v" ] && KVALLOC_DEVFS_FILE=/dev/vmalloc_test
[ -e $KVALLOC_DEBUGFS_FILE ] || {
	echo "Error! debugfs file does not exist. Driver loaded? Aborting..."
	exit 1
}
echo "KVALLOC_DEVFS_FILE = $KVALLOC_DEVFS_FILE"

# defaults
numbytes=1000
step_factor=50000

if [ $# -eq 2 ]; then
	numbytes=$1
	step_factor=$2
elif [ $# -eq 3 ]; then
	numbytes=$2
	step_factor=$3
fi
echo "
Running:"
[ $1 = "k" ] && echo "KMALLOC TEST"
[ $1 = "v" ] && echo "VMALLOC TEST"
echo "$(basename $0) $numbytes $step_factor
"

while [ true ]
do
	let kb=$numbytes/1024
	let mb=$numbytes/1048576
	echo "Attempting to alloc $numbytes bytes ($kb KB, $mb MB)"
	echo $numbytes > $KVALLOC_DEVFS_FILE || {
		let kb_fail=$numbytes/1024
		let mb_fail=$numbytes/1048576
		echo "FAILURE! AT $numbytes bytes = $kb_fail KB = $mb_fail MB. Aborting..."
		exit 1
	}
	let numbytes=numbytes+step_factor
done
exit 0

