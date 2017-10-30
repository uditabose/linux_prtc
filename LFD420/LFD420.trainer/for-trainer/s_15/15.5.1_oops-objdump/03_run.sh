MODULE_NAME=oops

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo 
fi

echo "+ >>>>>>>>>>>>>> will ooops <<<<<<<<<<<<<<<"
echo "+ do you really want to oops ?"
read a
if [[ $a == "Y" || $a == "y" || $a = "" ]]; then
        echo "+ gonna do it"

echo "+ insmod $MODULE_NAME.ko"
$SUDO insmod $MODULE_NAME.ko

echo "+ mount -t debugfs none /sys/kernel/debug"
$SUDO mount -t debugfs none /sys/kernel/debug

echo  "+ $SUDO sh -c 'echo "878" > /sys/kernel/debug/mydir/filen'"
$SUDO sh -c 'echo "878" > /sys/kernel/debug/mydir/filen'

echo "+ might need some delay - sleep 2"
$SUDO sleep 2

echo "+ rmmod $MODULE_NAME.ko"
$SUDO rmmod $MODULE_NAME.ko

fi
