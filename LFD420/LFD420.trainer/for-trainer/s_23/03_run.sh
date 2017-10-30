MODULE_NAME=lab1_chrdrv
DEVICE_NAME=mycdrv
MAJOR=700

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo 
fi

set -x
$SUDO rm -f /dev/$DEVICE_NAME

$SUDO insmod $MODULE_NAME.ko

$SUDO mknod -m 666 /dev/$DEVICE_NAME c 700 0

$SUDO bash -c "echo 'something' > /dev/mychrdrv"
$SUDO cat /dev/mychrdrv
sleep 1

$SUDO bash -c "echo 'Some Input' > /dev/${DEVICE_NAME}"
$SUDO dd if=/dev/mycdrv bs=11 count=1
sleep 1

echo "0123456789" > /tmp/somefile
$SUDO bash -c "cat /tmp/somefile > /dev/${DEVICE_NAME}"
$SUDO dd if=/dev/mycdrv bs=11 count=1
sleep 1 

$SUDO bash -c "dd if=/dev/urandom of=/dev/${DEVICE_NAME} bs=11 count=1"
$SUDO bash -c "dd if=/dev/${DEVICE_NAME} bs=11 count=1 | hexdump"
sleep 1

$SUDO bash -c "dd if=/dev/zero of=/dev/${DEVICE_NAME} bs=11 count=1"
$SUDO bash -c "dd if=/dev/${DEVICE_NAME} bs=11 count=1 | hexdump"
sleep 1

$SUDO bash -c "echo 'something else' > /dev/mychrdrv"
$SUDO cat /dev/mychrdrv
sleep 1

$SUDO rmmod $MODULE_NAME.ko

$SUDO rm -f /dev/$DEVICE_NAME

set +x
