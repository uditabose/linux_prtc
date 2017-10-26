USER_SPACE_NAME=lab1_sigorder

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

kill -l

$SUDO ./${USER_SPACE_NAME}
