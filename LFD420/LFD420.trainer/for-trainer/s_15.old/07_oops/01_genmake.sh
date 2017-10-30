make clean
rm -f Makefile
source ../env.sh
CPPFLAGS=-I${KERNEL_INCLUDE_PATH} ../../genmake

echo "you might want to add EXTRA_CFLAGS+=-g to your Makefile"
