USER_SPACE=lab1_limit

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

#echo "./${USER_SPACE} > user.txt"
#./${USER_SPACE} > user.txt

#echo "sudo ./${USER_SPACE} > sudo.txt"
#sudo ./${USER_SPACE} > sudo.txt

echo "./${USER_SPACE}"
./${USER_SPACE}

#echo "compare user.txt and sudo.txt"
