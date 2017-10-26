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

echo "echo h > /proc/sysrq-trigger"
read r
${SUDO} bash -c "echo h > /proc/sysrq-trigger"

echo "echo m > /proc/sysrq-trigger"
read r
${SUDO} bash -c "echo m > /proc/sysrq-trigger"

echo "echo t > /proc/sysrq-trigger"
read r
${SUDO} bash -c "echo t > /proc/sysrq-trigger"

