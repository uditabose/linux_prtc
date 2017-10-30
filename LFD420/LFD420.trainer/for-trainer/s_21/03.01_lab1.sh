MODULE_NAME=lab1_vma

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

PID=$PPID

$SUDO echo insmod $MODULE_NAME.ko pid=${PID}
$SUDO insmod $MODULE_NAME.ko pid=${PID}

echo "cat /proc/${PID}/maps"
cat /proc/${PID}/maps

echo "pmap -d ${PID}"
pmap -d ${PID}

$SUDO echo rmmod $MODULE_NAME.ko
$SUDO rmmod $MODULE_NAME.ko
