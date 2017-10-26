#USER_SPACE_NAME=lab1_hugepage_mm

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

if [ ! -d "/tmp/mnt" ]; then
  echo "creating /tmp/mnt/hugemmtestfile"
  $SUDO mkdir -p /tmp/mnt
fi


#mkdir -p /tmp/mnt/hugemmtestfile

$SUDO clear

#echo "open another terminal window and do:"
#echo "watch -d -n 1 cat /proc/meminfo"
#echo "to run the application press return"
#read r

#cat /proc/meminfo | grep -i huge

set -x
watch -d -n 1 'cat /proc/meminfo | grep -i huge' 
set +x

#sleep 5

#$SUDO ./${USER_SPACE_NAME} 

#cat /proc/meminfo | grep -i huge

#sleep 10

#killall watch
#set +x
#killall ./${USER_SPACE_NAME}
