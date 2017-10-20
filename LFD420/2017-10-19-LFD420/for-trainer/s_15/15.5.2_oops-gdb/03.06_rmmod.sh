MODULE_NAME=oops

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo 
fi

echo "+ rmmod $MODULE_NAME.ko"
$SUDO rmmod $MODULE_NAME.ko

