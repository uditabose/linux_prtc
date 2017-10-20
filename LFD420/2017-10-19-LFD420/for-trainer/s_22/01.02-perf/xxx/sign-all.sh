#!/bin/bash
source ../../env.sh
FILES=*.ko
for f in $FILES
do
  echo "Processing $f file..."
  set -x
  ${STAGING_DIR}/s_02/linux-${KERNEL_VER}/scripts/sign-file sha512 ${STAGING_DIR}/s_02/linux-${KERNEL_VER}/certs/signing_key.pem ${STAGING_DIR}/s_02/linux-${KERNEL_VER}/certs/signing_key.x509 $f
  set +x
done
