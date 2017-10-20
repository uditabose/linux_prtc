source ../../env.sh
make clean
rm -f Makefile
source ../../env.sh
CPPFLAGS=-I${KERNEL_INCLUDE_PATH} ../../genmake
