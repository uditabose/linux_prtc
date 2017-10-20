MODULE_NAME_1=lab2_sem1
MODULE_NAME_2=lab2_sem2
MODULE_NAME_3=lab2_sem3

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo 
fi

$SUDO clear

$SUDO echo "---> check gnome-system-log kern.log <---"
$SUDO echo

echo "lsmod | grep lab2"
echo "press <ENTER> to go on"
read r
lsmod | grep lab2

echo " "
echo "insmod $MODULE_NAME_1.ko"
echo "press <ENTER> to go on"
read r
$SUDO insmod $MODULE_NAME_1.ko
echo "lsmod | grep lab2"
lsmod | grep lab2

echo " "
echo "insmod $MODULE_NAME_2.ko"
echo "press <ENTER> to go on"
read r
$SUDO insmod $MODULE_NAME_2.ko
echo "lsmod | grep lab2"
lsmod | grep lab2

echo " "
echo "insmod $MODULE_NAME_3.ko &"
echo "press <ENTER> to go on"
read r
$SUDO insmod $MODULE_NAME_3.ko &
echo "lsmod | grep lab2"
lsmod | grep lab2
echo "$MODULE_NAME_3 is not loaded now!"
lsmod | grep lab2


echo " "
echo "rmmod  $MODULE_NAME_2.ko"
echo "press <ENTER> to go on"
read r
$SUDO rmmod  $MODULE_NAME_2.ko
echo "lsmod | grep lab2"
lsmod | grep lab2

echo " "
echo "rmmod  $MODULE_NAME_3.ko"
echo "rmmod  $MODULE_NAME_1.ko"
echo "press <ENTER> to go on"
read r 
$SUDO rmmod  $MODULE_NAME_3.ko
$SUDO rmmod  $MODULE_NAME_1.ko
echo "lsmod | grep lab2"
lsmod | grep lab2
