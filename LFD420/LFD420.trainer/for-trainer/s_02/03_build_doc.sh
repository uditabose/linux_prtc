HERE=$(pwd)

source ../env.sh

if [[ $UID -ne 0 ]]; then
    echo "$0 must be run as root"
    echo "e.g. sudo bash on Ubuntu"
    exit 1
fi

cd ${STAGING_DIR}/s_02

cd linux-${KERNEL_VER}

apt-get install xmlto tstools xmltex
#make htmldocs
#make psdocs - does not work
#make pdfdocs

make htmldocs 
make psdocs 
make pdfdocs
make rtfdocs 

cd ${HERE}
