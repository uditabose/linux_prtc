USER_SPACE_NAME=lab1_cfs

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

$SUDO ./${USER_SPACE_NAME}
