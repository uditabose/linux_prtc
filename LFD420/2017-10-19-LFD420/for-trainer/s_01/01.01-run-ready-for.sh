#!/bin/bash
source ../env.sh
set -x
./ready-for.sh ${TRAINING_ID}
./ready-for.sh --install ${TRAINING_ID} 
set +x
