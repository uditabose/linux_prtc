ST_1}HERE=$(pwd)
KERNEL_MODULE="trivial"

FILE_HIST_1="HIST_1"
FILE_HIST_2="HIST_2"
FILE_HIST_3="HIST_3"
FILE_HIST_4="HIST_4"
FILE_HIST_5="HIST_5"
FILE_VAL_IN_US="VAL_IN_US"

if [ "$(id -u)" == "0" ]; then
  unset SUDO
else
  SUDO=sudo
fi

source ../../env.sh
echo "+ $SUDO /home/student/bin/perf report"
echo "+ press <ENTER> to go on"
read r
#$SUDO /home/student/bin/perf report -g -n
$SUDO /home/student/bin/perf script | grep my_print > ${FILE_HIST_1}
#cut -f 1,2,3 ${FILE_HIST_1} > ${FILE_VAL_IN_US}
awk '{delim = " "; for (i=2;i<=NF-1;i++) {printf delim "%s", $i; delim = OFS}; printf "\n"}' ${FILE_HIST_1} > ${FILE_HIST_2}
awk '{delim = " "; for (i=2;i<=NF-1;i++) {printf delim "%s", $i; delim = OFS}; printf "\n"}' ${FILE_HIST_2} > ${FILE_HIST_3}
cat ${FILE_HIST_3} | sed -e 's/] \(.*\):/\1/' > ${FILE_HIST_4}
sed 's/\[//' ${FILE_HIST_4} > ${FILE_HIST_5}
# extract only the value in us
#awk -F":" '{print $3}' ${FILE_HIST_1}  > ${FILE_VAL_IN_US}
cd ${HERE}
