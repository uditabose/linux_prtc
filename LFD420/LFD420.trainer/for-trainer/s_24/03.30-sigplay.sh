USER_SPACE_NAME=sigplay

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

echo "check how many non-rt/rt signales are lost when blocking/non blocking signals are used"
echo "press <return> to go on"
read r

$SUDO ./${USER_SPACE_NAME}
