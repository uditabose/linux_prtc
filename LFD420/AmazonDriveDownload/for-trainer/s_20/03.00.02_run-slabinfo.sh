if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

#$SUDO apt-get install libunwind8-dev libaudit-dev liblzma-dev libslang2-dev

HERE=$(pwd)
source ../env.sh
set -x
#zegrep "CONFIG_PERF_EVENTS|CONFIG_HW_PERF_EVENTS" /proc/config.gz
cd ${KROOT}/tools/vm
sudo ./slabinfo
set +x
cd ${HERE}
