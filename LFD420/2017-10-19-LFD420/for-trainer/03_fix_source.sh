if [ $# -eq 0 ] ; then
    echo "03_fix_source.sh <file you want to fix>"
    exit 0
fi

#DEVKIT=armv7a
source ../env.sh
echo "+ ${KROOT}/scripts/checkpatch.pl --file --fix $1"
${KROOT}/scripts/checkpatch.pl --file --fix $1

echo "+ mv $1.EXPERIMENTAL-checkpatch-fixes $1"
mv $1.EXPERIMENTAL-checkpatch-fixes $1

echo "+ git diff $1"
git diff $1

echo "+ ${KROOT}/scripts/checkpatch.pl --file --terse $1"
${KROOT}/scripts/checkpatch.pl --file --terse $1
