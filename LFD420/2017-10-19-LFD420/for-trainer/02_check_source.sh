if [ $# -eq 0 ] ; then
    echo "02_check_source.sh <file you want to check>"
    exit 0
fi

#DEVKIT=armv7a
source ../env.sh
echo "+ ${KROOT}/scripts/checkpatch.pl --file --terse $1"
${KROOT}/scripts/checkpatch.pl --file --terse $1
