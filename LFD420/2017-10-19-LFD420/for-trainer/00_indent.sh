if [ $# -eq 0 ] ; then
    echo "00_indent.sh <file you want to check>"
    exit 0
fi

#DEVKIT=armv7a
source ../env.sh
echo "+ ${KROOT}/scripts/Lindent $1"
${KROOT}/scripts/Lindent $1
