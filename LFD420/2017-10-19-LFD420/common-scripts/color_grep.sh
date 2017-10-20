#!/bin/bash 

# color grep
function color_grep () {
      grep --color -E ${1}
}

export GREP="color_grep"
