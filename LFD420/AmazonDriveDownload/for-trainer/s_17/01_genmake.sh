make clean
rm -f Makefile
source ../env.sh
PATH=../:$PATH
export LDLIBS=" -lm"
CPPFLAGS=-I${KERNEL_INCLUDE_PATH} ../genmake
