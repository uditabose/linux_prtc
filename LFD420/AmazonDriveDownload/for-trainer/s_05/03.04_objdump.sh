
echo objdump -h lab3_module1.ko
objdump -h lab3_module1.ko
echo press return to go on
read r
echo objdump -s -j .modinfo lab3_module1.ko
objdump -s -j .modinfo lab3_module1.ko
