USER_SPACE_NAME=lab3_hugewaste

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

set -x
cat /proc/sys/vm/nr_hugepages
$SUDO sh -c "echo 10 > /proc/sys/vm/nr_hugepages"
cat /proc/sys/vm/nr_hugepages

./${USER_SPACE_NAME} 9
set +x
