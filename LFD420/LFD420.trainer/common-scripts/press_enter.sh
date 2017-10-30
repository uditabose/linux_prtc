#!/bin/bash 

# for this to work we need to 
#   export WORKSPACE="jenkins" in a top level config file e.g. env.sh
#   export PEXPECT_PRESS="yes" in a top level config file e.g. env.sh if you want PEXPECT to press <ENTER> although WORKSPACE="jenkins" was set

function press_enter {
#echo 0: ${0}
#echo 1: ${1}
#echo 2: ${2}
  if [[ $WORKSPACE = *jenkins* ]]; then
     if [[ $PEXPECT_PRESS = *yes* ]]; then
        # echo "PEXPECT should press <ENTER>"
        echo "+ press <ENTER> to go on"
        read r
     else
        echo "+ WORKSPACE '$WORKSPACE' contains jenkins"
        echo "+ would normally wait for input from command line"
     fi
  else # WORKSPACE is not jenkins
     echo "+ press <ENTER> to go on" 
     read r
  fi
}
