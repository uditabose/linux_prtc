source ../../env.sh
MODULE_NAME="6-22-kernellist"

if [ "$(id -u)" == "0" ]; then
	unset SUDO
else
	SUDO=sudo
fi

$SUDO clear

$SUDO echo "---> check gnome-system-log kern.log <---"
$SUDO echo

set -x

$SUDO cat /proc/sys/kernel/printk

$SUDO insmod $MODULE_NAME.ko
sleep 2
$SUDO rmmod $MODULE_NAME.ko

dmesg | tail -32

set +x
