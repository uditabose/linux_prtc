#clear
export TRAINING_ID_SHORT="420"
export TRAINING_ID="LFD${TRAINING_ID_SHORT}"

export KERNEL_VER="4.13.3"
export KERNEL_CONFIG="${KERNEL_VER}"

KROOT="/lib/modules/$(uname -r)/build"
KERNEL_INCLUDE_PATH="${KROOT}/arch/x86/include"

echo "------------------------------------------"
echo "KERNEL_VER: ${KERNEL_VER}"
echo "KERNEL_INCLUDE_PATH: ${KERNEL_INCLUDE_PATH}"
echo "KROOT: ${KROOT}"

export TARGET_BOARD="kvm"

export DL_DIR="${HOME}/${TRAINING_ID}-download"
export STAGING_DIR="${HOME}/${TARGET_BOARD}/${TRAINING_ID}-staging"
export EXTRA_DIR="${HOME}/${TARGET_BOARD}/${TRAINING_ID}-extra-stuff"

if [ ! -d ${DL_DIR} ];
then
  mkdir -p ${DL_DIR}
else
  echo "DL_DIR: ${DL_DIR} already exists"
fi

if [ ! -d ${STAGING_DIR} ];
then
  mkdir -p ${STAGING_DIR}
else
  echo "STAGING_DIR: ${STAGING_DIR} already exists"
fi

if [ ! -d ${EXTRA_DIR} ];
then
  mkdir -p ${EXTRA_DIR}
else
  echo "EXTRA_DIR: ${EXTRA_DIR} already exists"
fi
export EXTRA_STUFF=${EXTRA_DIR}
echo "------------------------------------------"
