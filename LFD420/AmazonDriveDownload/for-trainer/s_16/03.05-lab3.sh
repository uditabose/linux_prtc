USER_SPACE_NAME=lab3_scheduler

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

$SUDO ./${USER_SPACE_NAME}
