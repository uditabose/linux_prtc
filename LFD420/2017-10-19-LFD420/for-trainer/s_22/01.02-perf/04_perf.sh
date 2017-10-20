if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

HERE=$(pwd)
source ../../env.sh
set -x
$SUDO /home/student/bin/perf
$SUDO /home/student/bin/perf list
set +x
cd ${HERE}
