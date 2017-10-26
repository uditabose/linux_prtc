source ../../common-scripts/common.sh

MODULE_NAME=lab2_ioctl
USER_SPACE=lab2_ioctl_test
DEVICE_NAME=mycdrv
#MAJOR=700

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

#echo $SUDO rm -f /dev/$DEVICE_NAME
#echo $SUDO mknod /dev/$DEVICE_NAME c $MAJOR 0
#echo $SUDO chmod 666 /dev/$DEVICE_NAME

#$SUDO rm -f /dev/$DEVICE_NAME
#$SUDO mknod /dev/$DEVICE_NAME c $MAJOR 0
#$SUDO chmod 666 /dev/$DEVICE_NAME

echo $SUDO insmod $MODULE_NAME.ko
$SUDO insmod $MODULE_NAME.ko

plus_echo "$SUDO chmod 666 /dev/$DEVICE_NAME"
$SUDO chmod 666 /dev/$DEVICE_NAME

plus_echo "ls -la /dev/$DEVICE_NAME"
ls -la /dev/$DEVICE_NAME

plus_echo "./${USER_SPACE} /dev/$DEVICE_NAME"
./${USER_SPACE} /dev/$DEVICE_NAME

#echo $SUDO insmod $MODULE_NAME.ko
#$SUDO insmod $MODULE_NAME.ko

#echo $SUDO ./$USER_SPACE
#./${USER_SPACE}

$SUDO rmmod $MODULE_NAME.ko
echo $SUDO rmmod $MODULE_NAME.ko
