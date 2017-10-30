MODULE1_NAME=lab3_module1
MODULE2_NAME=lab3_module2

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

$SUDO echo insmod $MODULE1_NAME.ko
$SUDO insmod $MODULE1_NAME.ko

$SUDO echo insmod $MODULE2_NAME.ko
$SUDO insmod $MODULE2_NAME.ko

$SUDO echo rmmod $MODULE2_NAME.ko
$SUDO rmmod $MODULE2_NAME.ko

$SUDO echo rmmod $MODULE1_NAME.ko
$SUDO rmmod $MODULE1_NAME.ko
