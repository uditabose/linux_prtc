USER_SPACE_NAME=lab1_wastemem

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

$SUDO /sbin/swapoff -a

#echo "how many MB to waste?"
#echo "MB: "
#read MB

for (( c=5000; c<=100000; c+=1000 ))
do
	echo "============================="
        echo "$SUDO ./${USER_SPACE_NAME} ${c}"
	$SUDO ./${USER_SPACE_NAME} ${c}
        RETVAL=$?
        echo "retval: $RETVAL"
        if [ $RETVAL != 0 ]; then
          break
        fi
done


#echo $SUDO ./${USER_SPACE_NAME} ${MB}
#$SUDO ./${USER_SPACE_NAME} ${MB}

$SUDO /sbin/swapon -a
