source ../env.sh
make clean
rm -f Makefile
source ../env.sh
set -x
CPPFLAGS=-I${KERNEL_INCLUDE_PATH}/generated/uapi ../genmake
set +x
