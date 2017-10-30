source ../../env.sh
PROJECT_NAME=unnamed_sem_wait
EXE=${PROJECT_NAME}

clear

echo "read the source luke"
echo "vim $PROJECT_NAME.c"
read r
vim $PROJECT_NAME.c

echo "====> compiling $EXE"
read r
make clean
make 
echo "<==== compiling $EXE"

echo "====> executing $EXE 2 3"
read r
./$EXE 2 3
echo "<==== executing $EXE 2 3"

echo "====> executing $EXE 2 1"
read r
./$EXE 2 1
echo "<==== executing $EXE 2 1"

echo "====> executing strace ./$EXE 0 10"
read r
strace ./$EXE 0 10
echo "<==== executing strace ./$EXE 0 10"



