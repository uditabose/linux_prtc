MODULE_NAME=lab2_handler
USER_SPACE_NAME=lab2_handler_test

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

echo "./${USER_SPACE_NAME} &"
./${USER_SPACE_NAME} &

sleep 1


echo "enter PID and press return to go on"
read PID

echo "enter Signal and press return to go on"
read SIGNAL

$SUDO echo insmod $MODULE_NAME.ko pid=${PID} signo=${SIGNAL}
$SUDO insmod $MODULE_NAME.ko pid=${PID} signo=${SIGNAL}

$SUDO echo rmmod $MODULE_NAME.ko
$SUDO rmmod $MODULE_NAME.ko

echo "$SUDO bash -c \"kill -9 ${PID}\""
$SUDO bash -c "kill -9 ${PID}"

