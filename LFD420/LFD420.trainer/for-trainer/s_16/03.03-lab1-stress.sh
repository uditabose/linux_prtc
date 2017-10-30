SCRIPT_NAME=lab1_testloop.sh

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

stress -c 8 &
$SUDO ./${SCRIPT_NAME} | tee lab1-stress.txt

#echo "sorted:"
#
#awk '{print $NF,$0}' lab1-stress.txt | sort -nr | cut -f2- -d' ' | tee lab1-stress-sorted.txt

echo "========================================="
cat lab1-stress.txt


echo "be sure to kill stress: pkill -9 stress"
set -x
pkill -9 stress
set +x
