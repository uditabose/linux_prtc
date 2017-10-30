MODULE_NAME_1=lab1_mutex1
MODULE_NAME_2=lab1_mutex2
MODULE_NAME_3=lab1_mutex3

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo 
fi

$SUDO clear

$SUDO echo "---> check gnome-system-log kern.log <---"
$SUDO echo

echo "lsmod | grep lab1"
echo "press <ENTER> to go on"
read r
lsmod | grep lab1

echo " "
echo "insmod $MODULE_NAME_1.ko"
echo "press <ENTER> to go on"
read r
$SUDO insmod $MODULE_NAME_1.ko
echo "lsmod | grep lab1"
lsmod | grep lab1

echo " "
echo "insmod $MODULE_NAME_2.ko"
echo "press <ENTER> to go on"
read r
$SUDO insmod $MODULE_NAME_2.ko
echo "lsmod | grep lab1"
lsmod | grep lab1

echo " "
echo "insmod $MODULE_NAME_3.ko &"
echo "press <ENTER> to go on"
read r
$SUDO insmod $MODULE_NAME_3.ko &
echo "lsmod | grep lab1"
lsmod | grep lab1
echo "$MODULE_NAME_3 is blocking now!"
lsmod | grep lab1


echo " "
echo "rmmod  $MODULE_NAME_2.ko"
echo "press <ENTER> to go on"
read r
$SUDO rmmod  $MODULE_NAME_2.ko
echo "lsmod | grep lab1"
lsmod | grep lab1

echo " "
echo "rmmod  $MODULE_NAME_3.ko"
echo "rmmod  $MODULE_NAME_1.ko"
echo "press <ENTER> to go on"
read r 
$SUDO rmmod  $MODULE_NAME_3.ko
$SUDO rmmod  $MODULE_NAME_1.ko
echo "lsmod | grep lab1"
lsmod | grep lab1
