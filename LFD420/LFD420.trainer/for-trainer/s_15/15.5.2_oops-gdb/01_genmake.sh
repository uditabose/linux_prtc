make clean
rm -f Makefile
source ../../env.sh
source ../../../common-scripts/common.sh
CPPFLAGS=-I${KERNEL_INCLUDE_PATH} ../../genmake

plus_echo_green "you might want to add ccflags-y += -g to your Makefile"
press_enter
vim Makefile
