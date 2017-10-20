if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

HERE=$(pwd)
source ../../env.sh
set -x
$SUDO /home/student/bin/perf list | awk -F: '/Tracepoint event/ { lib[$1]++ } END {
   for (l in lib) { printf "  %-16s %d\n", l, lib[l] } }' | sort | column
$SUDO /home/student/bin/perf list | grep printk
set +x
cd ${HERE}
