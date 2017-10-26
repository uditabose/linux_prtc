if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

echo "cat /proc/sys/kernel/sysrq"
read r
${SUDO} cat /proc/sys/kernel/sysrq

echo "echo 1 > /proc/sys/kernel/sysrq"
read r
${SUDO} bash -c "echo 1 > /proc/sys/kernel/sysrq"

echo "echo g > /proc/sysrq-trigger"
read r
${SUDO} bash -c "echo g > /proc/sysrq-trigger"
