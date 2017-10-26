echo "stats:"
echo "cpuinfo_cur_freq - Show the current frequency of your CPU(s). You can also find this out by doing a cat /proc/cpuinfo."
sudo cat /sys/devices/system/cpu/*/cpufreq/cpuinfo_cur_freq

echo "cpuinfo_max_freq - Show the maximum frequency your CPU(s) can scale to."
sudo cat /sys/devices/system/cpu/*/cpufreq/cpuinfo_max_freq

echo "cpuinfo_min_freq - Show the minimum frequency your CPU(s) can scale to."
sudo cat /sys/devices/system/cpu/*/cpufreq/cpuinfo_min_freq

echo "scaling_available_frequencies - Show all the available frequencies your CPU(s) can scale to."
sudo cat /sys/devices/system/cpu/*/cpufreq/scaling_available_frequencies

echo "governors:"
sudo cat /sys/devices/system/cpu/*/cpufreq/scaling_available_governors

echo "scaling_cur_freq - Show the available frequency your CPU(s) are scaled to currently."
sudo cat /sys/devices/system/cpu/*/cpufreq/scaling_cur_freq

echo "scaling_driver - Show the cpufreq driver the CPU(s) are using."
sudo cat /sys/devices/system/cpu/*/cpufreq/scaling_driver 

#echo "forcing to fixed frequency: type/copy paste yourself with appropriate values"
#echo "will be gone after reboot"
#echo "sudo sh -c \"echo 1600000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq\"" 
#echo "sudo sh -c \"echo 1600000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq\"" 
#echo "sudo sh -c \"echo 1600000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_max_freq\"" 
#echo "sudo sh -c \"echo 1600000 > /sys/devices/system/cpu/cpu1/cpufreq/scaling_min_freq\"" 
