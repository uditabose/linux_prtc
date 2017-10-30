source ../env.sh

echo "here you can see if you are on a 32-bit or 64-bit system"
echo "uname -a"
uname -a


if [[ $WORKSPACE = *jenkins* ]]; then
  echo "WORKSPACE '$WORKSPACE' contains jenkins"
  echo "would normally wait for input from command line"
else
  echo "press <ENTER> to go on"
  read r
fi

echo ${TRAINING_ID}

if [ ! -d ${STAGING_DIR}/s_02 ];
then
  mkdir -p ${STAGING_DIR}/s_02
else
  echo "STAGING_DIR for s_02: ${STAGING_DIR}/s_02 already exists"
fi

cp ${DL_DIR}/s_02/linux-${KERNEL_VER}.tar.xz ${STAGING_DIR}/s_02
cp config-${KERNEL_CONFIG}_x86_64 ${STAGING_DIR}/s_02
cp DO_KERNEL.sh ${STAGING_DIR}/s_02
chmod +x ${STAGING_DIR}/s_02/DO_KERNEL.sh
