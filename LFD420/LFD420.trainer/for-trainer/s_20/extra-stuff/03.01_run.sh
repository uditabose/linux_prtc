MODULE_NAME=misc_kmalloc

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo 
fi

echo "+ $SUDO insmod $MODULE_NAME.ko"
$SUDO insmod $MODULE_NAME.ko

echo "+ $SUDO lsmod | grep $MODULE_NAME"
$SUDO lsmod | grep $MODULE_NAME

echo "+ $SUDO ./test_kvalloc.sh k 50000 102400"
$SUDO ./test_kvalloc.sh k 50000 102400

echo "+ $SUDO rmmod $MODULE_NAME.ko"
$SUDO rmmod $MODULE_NAME.ko

echo "+ $SUDO lsmod | grep $MODULE_NAME"
$SUDO lsmod | grep $MODULE_NAME

echo "+ $SUDO dmesg | tail -n 10"
$SUDO dmesg | tail -n 10

echo "+ This was the kmalloc test"
