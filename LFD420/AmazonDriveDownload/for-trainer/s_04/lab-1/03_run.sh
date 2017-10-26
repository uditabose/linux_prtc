for i in $(seq 1 10)
do
  echo "------>"
  echo "loop: ${i}"
  echo "+ stress --cpu 8 --io 4 --vm 6 --vm-bytes 128M --timeout 10s &"
  stress --cpu 8 --io 4 --vm 6 --vm-bytes 128M --timeout 10s &
  # get the PID of the process started before
  PID=$!
  echo "PID: ${PID}"
 while sleep 1
#  echo "loadavg: $(cat /proc/loadavg)"
   kill -0 ${PID} > /dev/null 2>&1
 do
   echo "loadavg: $(cat /proc/loadavg)"
 done
echo "loadavg: $(cat /proc/loadavg)"
 echo "<-----"
done

echo "stress test done"
