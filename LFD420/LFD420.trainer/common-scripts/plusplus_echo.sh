#!/bin/bash 

# we'll prepend a + and try to execute as well
# Note: This will not always work!
#       command substitution is not treated as set -x, 
#       since it is performed by the invoking shell, not inside the function.
function plusplus_echo () {
  echo "$PS4$@" 1>&2
  "$@"
}

