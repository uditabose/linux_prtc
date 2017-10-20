SCRIPT_NAME=lab1_testloop.sh

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO clear

$SUDO ./${SCRIPT_NAME} | tee lab1.txt

echo "========================================="

cat lab1.txt

#echo "sorted:"

#awk '{print $NF,$0}' lab1.txt | sort -nr | cut -f2- -d' ' | tee lab1-sorted.txt
#awk '{print $NF,$0}' lab1.txt | sort -nr | cut -f2- -d' ' | tee lab1-sorted.txt
