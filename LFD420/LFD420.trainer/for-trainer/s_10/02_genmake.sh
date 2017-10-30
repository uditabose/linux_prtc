make clean
source ../env.sh
rm -f Makefile
CPPFLAGS=-I${KERNEL_INCLUDE_PATH} ../genmake
