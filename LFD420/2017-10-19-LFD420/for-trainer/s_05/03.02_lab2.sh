MODULE_NAME=lab2_utsname

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

$SUDO echo "---> check gnome-system-log kern.log <---"
$SUDO echo

$SUDO echo cat /proc/sys/kernel/printk
$SUDO cat /proc/sys/kernel/printk

$SUDO echo insmod $MODULE_NAME.ko
$SUDO insmod $MODULE_NAME.ko

echo "lsmod | grep lab"
lsmod | grep lab

#ls /sys/module/$MODULE_NAME/sections

$SUDO echo rmmod $MODULE_NAME.ko
$SUDO rmmod $MODULE_NAME.ko

set -x
uname -a
set +x
