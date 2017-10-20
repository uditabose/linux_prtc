if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

$SUDO apt install libiberty-dev binutils-dev libdw-dev libelf-dev libunwind8-dev libaudit-dev liblzma-dev libslang2-dev elfutils

HERE=$(pwd)
source ../../env.sh
set -x
zegrep "CONFIG_PERF_EVENTS|CONFIG_HW_PERF_EVENTS" /proc/config.gz
cd ${KROOT}/tools/perf
#sudo make clean
$SUDO make -j $(getconf _NPROCESSORS_ONLN) perf
$SUDO make install
set +x
cd ${HERE}
