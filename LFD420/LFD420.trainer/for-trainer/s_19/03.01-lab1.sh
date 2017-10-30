USER_SPACE_NAME=lab1_hugepage_mm

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

set -x
cat /proc/sys/vm/nr_hugepages
$SUDO sh -c "echo 10 > /proc/sys/vm/nr_hugepages"
cat /proc/sys/vm/nr_hugepages


sudo mkdir -p /mnt/huge
sudo mount -t hugetlbfs none /mnt/huge -o size=1g
mount
set +x
echo "Press <ENTER> to go on"
read r

set -x
$SUDO ./${USER_SPACE_NAME} /mnt/huge/tmpfile

sudo umount /mnt/huge
set +x
