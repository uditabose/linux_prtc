USER_SPACE_NAME=lab3_wastemem

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

echo "how many MB to defragment?"
echo "MB: "
read MB

echo $SUDO ./${USER_SPACE_NAME} ${MB}
$SUDO ./${USER_SPACE_NAME} ${MB}
