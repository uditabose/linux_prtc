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

echo "+ mount -t debugfs none /sys/kernel/debug"
$SUDO mount -t debugfs none /sys/kernel/debug

echo  "+ $SUDO sh -c 'echo "878" > /sys/kernel/debug/mydir/filen'"
$SUDO sh -c 'echo "878" > /sys/kernel/debug/mydir/filen'
fi
