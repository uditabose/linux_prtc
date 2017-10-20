MODULE_NAME=lab3_launch_cp

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

rm -f /tmp/syslog

$SUDO echo "---> check gnome-system-log kern.log <---"
$SUDO echo

$SUDO echo cat /proc/sys/kernel/printk
$SUDO cat /proc/sys/kernel/printk

$SUDO echo insmod $MODULE_NAME.ko
$SUDO insmod $MODULE_NAME.ko

$SUDO echo ls /var/log/syslog
ls /var/log/syslog

sleep 5

$SUDO echo rmmod $MODULE_NAME.ko
$SUDO rmmod $MODULE_NAME.ko

$SUDO echo ls /tmp/syslog
ls /tmp/syslog

$SUDO echo "try sudo cat /tmp/syslog"
