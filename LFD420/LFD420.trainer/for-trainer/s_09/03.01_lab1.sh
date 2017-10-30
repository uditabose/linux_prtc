MODULE_NAME=lab1_syscall_module
USER_SPACE=lab1_syscall_test

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
$SUDO echo $USER_SPACE
$SUDO echo rmmod $MODULE_NAME.ko

$SUDO insmod $MODULE_NAME.ko
./${USER_SPACE}
$SUDO rmmod $MODULE_NAME.ko
