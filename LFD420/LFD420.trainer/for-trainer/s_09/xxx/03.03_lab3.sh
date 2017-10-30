MODULE_NAME=lab3_stealsyscalls
USER_SPACE=lab3_makesyscalls

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

$SUDO ./lab3_loadit.sh sys_call_table

echo need to input address from above
read ADDRESS
echo using address: $ADDRESS

$SUDO echo insmod $MODULE_NAME.ko address=$ADDRESS
$SUDO insmod $MODULE_NAME.ko address=$ADDRESS

$SUDO echo $USER_SPACE
./${USER_SPACE}

$SUDO echo rmmod $MODULE_NAME.ko
$SUDO rmmod $MODULE_NAME.ko
