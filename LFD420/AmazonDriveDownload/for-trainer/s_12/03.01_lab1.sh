source ../../common-scripts/common.sh

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

if [ ! -d "/dev/cpuset" ]; then
  plus_on
  ${SUDO} mkdir /dev/cpuset
  ${SUDO} mount -t cgroup -o cpuset cpuset /dev/cpuset 
  plus_off
fi

plus_on
ls -l /dev/cpuset
plus_off
press_enter

if [ ! -d "/dev/cpuset/newcpuset" ]; then
  plus_off
  ${SUDO} mkdir /dev/cpuset/newcpuset
  plus_on
fi

echo "default cpuset:"
plus_on
cat /dev/cpuset/cpuset.cpus
cat /dev/cpuset/cpuset.mems
plus_off

echo "newcpuset:"
plus_on
cat /dev/cpuset/newcpuset/cpuset.cpus
cat /dev/cpuset/newcpuset/cpuset.mems
plus_off

echo "modify newcpuset:"
plus_on
${SUDO} bash -c "echo 1 > /dev/cpuset/newcpuset/cpuset.cpus"
${SUDO} bash -c "echo 0 > /dev/cpuset/newcpuset/cpuset.mems"
plus_off

echo "newcpuset:"
plus_on
cat /dev/cpuset/newcpuset/cpuset.cpus
cat /dev/cpuset/newcpuset/cpuset.mems
plus_off

echo "assign shell to new cpuset:"
plus_on
SHELL_PID=$$
plus_off
echo "shell PID=${SHELL_PID}"

plus_on
${SUDO} bash -c "echo ${SHELL_PID} > /dev/cpuset/newcpuset/tasks"
plus_off
echo "tasks in new cpuset:"
plus_on
cat /dev/cpuset/newcpuset/tasks
plus_off

plus_on
taskset -p ${SHELL_PID}
cat /proc/${SHELL_PID}/status
cat /proc/${SHELL_PID}/cpuset
cat /proc/${SHELL_PID}/cgroup
plus_off
