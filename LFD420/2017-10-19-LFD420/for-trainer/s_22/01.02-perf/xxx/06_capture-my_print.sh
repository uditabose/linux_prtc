HERE=$(pwd)
KERNEL_MODULE="trivial"
if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

source ../../env.sh
set -x
$SUDO insmod ${KERNEL_MODULE}.ko
#$SUDO /home/student/bin/perf list | grep printk
$SUDO /home/student/bin/perf probe -d my_print -d my_init -d printk
$SUDO /home/student/bin/perf probe -m ${HERE}/${KERNEL_MODULE}.ko  my_print

#$SUDO /home/student/bin/perf probe -a 'printk'

#$SUDO /home/student/bin/perf probe -F | grep printk
set +x
echo "+ $SUDO /home/student/bin/perf probe -L printk"
echo "+ press <ENTER> to go on"
read r
#$SUDO /home/student/bin/perf probe -L printk
set -x
#$SUDO /home/student/bin/perf record -e probe:printk
#$SUDO /home/student/bin/perf record -g -e probe:my_print -aR insmod ${HERE}/${KERNEL_MODULE}.ko;sleep 5
$SUDO /home/student/bin/perf record -T -g -e probe:my_print -aR sudo sh -c "echo 1 > /dev/mycdrv";sleep 5
#$SUDO /home/student/bin/perf record -a -T sudo sh -c "echo 1 > /dev/mycdrv";sleep 5
set +x
echo "+ $SUDO /home/student/bin/perf probe -L printk"
echo "+ press <ENTER> to go on"
read r
#SUDO /home/student/bin/perf record -e probe:printk -aR insmod ${HERE}/${KERNEL_MODULE}.ko;sleep 1
$SUDO rmmod ${KERNEL_MODULE}
set +x
cd ${HERE}
