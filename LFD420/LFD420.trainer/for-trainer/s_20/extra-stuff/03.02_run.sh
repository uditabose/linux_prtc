MODULE_NAME=misc_vmalloc

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo 
fi

echo "+ $SUDO insmod $MODULE_NAME.ko"
$SUDO insmod $MODULE_NAME.ko

echo "+ $SUDO lsmod | grep $MODULE_NAME"
$SUDO lsmod | grep $MODULE_NAME

memtot=`grep -i memtotal /proc/meminfo`
echo "+ grep -i memtotal /proc/meminfo"
echo ${memtot}

echo "+ the OOM killer will make the system unusable"
echo "+ press <ENTER> to go on"
read r

echo "+ $SUDO ./test_kvalloc.sh v 500000 5242880"
$SUDO ./test_kvalloc.sh v 500000 5242880

#echo "+ $SUDO ./test_kvalloc.sh v 50000 102400"
#$SUDO ./test_kvalloc.sh v 50000 102400

echo "+ $SUDO rmmod $MODULE_NAME.ko"
$SUDO rmmod $MODULE_NAME.ko

echo "+ $SUDO lsmod | grep $MODULE_NAME"
$SUDO lsmod | grep $MODULE_NAME

echo "+ $SUDO dmesg | tail -n 40"
$SUDO dmesg | tail -n 40

echo "+ This was the vmalloc test"
echo ${memtot}
