if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

if [ ! -d "/dev/cpuset" ]; then
  ${SUDO} mkdir /dev/cpuset
  ${SUDO} mount -t cgroup -o cpuset cpuset /dev/cpuset 
fi

ls -l /dev/cpuset

if [ ! -d "/dev/cpuset/newcpuset" ]; then
  ${SUDO} mkdir /dev/cpuset/newcpuset
fi

echo "default cpuset:"
cat /dev/cpuset/cpuset.cpus
cat /dev/cpuset/cpuset.mems

echo "newcpuset:"
cat /dev/cpuset/newcpuset/cpuset.cpus
cat /dev/cpuset/newcpuset/cpuset.mems

echo "modify newcpuset:"
${SUDO} bash -c "echo 1 > /dev/cpuset/newcpuset/cpuset.cpus"
${SUDO} bash -c "echo 0 > /dev/cpuset/newcpuset/cpuset.mems"

echo "newcpuset:"
cat /dev/cpuset/newcpuset/cpuset.cpus
cat /dev/cpuset/newcpuset/cpuset.mems

echo "assign shell to new cpuset:"
SHELL_PID=$$
echo "shell PID=${SHELL_PID}"

${SUDO} bash -c "echo ${SHELL_PID} > /dev/cpuset/newcpuset/tasks"
echo "tasks in new cpuset:"
cat /dev/cpuset/newcpuset/tasks

