MODULE_NAME=oops

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo 
fi

echo "+ insmod $MODULE_NAME.ko"
$SUDO insmod $MODULE_NAME.ko

