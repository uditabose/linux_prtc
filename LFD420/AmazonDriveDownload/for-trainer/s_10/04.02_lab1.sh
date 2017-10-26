MODULE_NAME=lab1_taints

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

set -x
lsmod
set +x

echo "+ cat /proc/sys/kernel/tainted"
cat /proc/sys/kernel/tainted
echo "hex:"
echo "obase=16; $(cat /proc/sys/kernel/tainted)" | bc
echo "check Documentation/sysctl/kernel.txt"


$SUDO echo rmmod $MODULE_NAME.ko
$SUDO rmmod $MODULE_NAME.ko


