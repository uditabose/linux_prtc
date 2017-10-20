#!/bin/bash 

# for this to work we need to 
#   export WORKSPACE="jenkins" in a top level config file e.g. env.sh
#   in shell script: plus_vim_read mala

# plus vim
function plus_vim_read () {
#echo 0: ${0}
#echo 1: ${1}
#echo 2: ${2}

   if [[ $WORKSPACE = *jenkins* ]]; then
       echo "+ WORKSPACE=jenkins"
       if [ -f "${1}" ]; then
          echo "+ cat ${1}"
          cat ${1}
       else
          echo "+ file \"${1}\" does not exist"
       fi
   else
       echo "+ WORKSPACE is undefined"
       echo "+ vim ${1}"
       vim ${1}
   fi
}
