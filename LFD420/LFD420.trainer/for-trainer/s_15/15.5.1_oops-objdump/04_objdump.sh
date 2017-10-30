# length of the my_write function is 60 lines
LINES="60"
# my_write+0x54 = 0x80 + 0x54 = 0xD4"
OFFSET="d4"

MODULE_NAME=oops

OLD_PATH=$PATH
PWD=`pwd`

source ../../env.sh
source ../../../common-scripts/common.sh

echo "+ ${CROSS_COMPILE}objdump --source -f $MODULE_NAME.ko"
press_enter
${CROSS_COMPILE}objdump --source -f $MODULE_NAME.ko

echo "+ my_write is ${LINES} lines long"
echo "+ ${CROSS_COMPILE}objdump --source -f $MODULE_NAME.ko | grep -C ${LINES} \"^my_write\""
press_enter
${CROSS_COMPILE}objdump --source -f $MODULE_NAME.ko | grep -C ${LINES} "^my_write"

echo "+ search for my_write+0x${OFFSET}"
echo "+ ${CROSS_COMPILE}objdump --source -f $MODULE_NAME.ko | grep -C ${LINES} \"^my_write\" | grep \"${OFFSET}:\""
press_enter
${CROSS_COMPILE}objdump --source -f $MODULE_NAME.ko | grep -C ${LINES} "^my_write" | grep "${OFFSET}:"

PATH=$OLD_PATH
cd $PWD
