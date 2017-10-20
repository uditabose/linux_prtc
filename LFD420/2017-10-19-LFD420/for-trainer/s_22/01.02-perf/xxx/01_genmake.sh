make clean
rm -f Makefile
source ../../env.sh
CPPFLAGS=-I${KERNEL_INCLUDE_PATH} ../../genmake

echo "you might want to add ccflags-y += -g to your Makefile"
press_enter
vim Makefile

