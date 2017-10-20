make clean
./01_genmake.sh
rm -f Makefile

pushd 02.01-strace
./10_clean.sh
popd

pushd 15.5.2_oops-gdb
./10_clean.sh
popd

pushd 15.5.1_oops-objdump
./10_clean.sh
popd
