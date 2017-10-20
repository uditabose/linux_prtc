MODULE_NAME=lab2_debugfs

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

echo "$SUDO cat /sys/kernel/debug/myname"
$SUDO cat /sys/kernel/debug/myname

echo "$SUDO bash -c \"echo 666 > /sys/kernel/debug/myname\""
$SUDO bash -c "echo 666 > /sys/kernel/debug/myname"

echo "$SUDO cat /sys/kernel/debug/myname"
$SUDO cat /sys/kernel/debug/myname

echo "$SUDO cat /sys/kernel/debug/mydir/filen"
$SUDO cat /sys/kernel/debug/mydir/filen

$SUDO echo rmmod $MODULE_NAME.ko
$SUDO rmmod $MODULE_NAME.ko
