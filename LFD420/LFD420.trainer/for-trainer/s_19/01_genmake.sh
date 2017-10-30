make clean
rm -f Makefile
source ../env.sh
PATH=../:$PATH
export LDLIBS="-L /usr/local/lib64 -lhugetlbfs"
CPPFLAGS=-I${KERNEL_INCLUDE_PATH} ../genmake
