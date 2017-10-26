#!/bin/bash 

# we'll just prepend a + 
function plus_echo_red () {
  tput setaf 1; echo "$PS4$@"
  tput sgr0
}

function plus_echo_green () {
  tput setaf 2; echo "$PS4$@"
  tput sgr0
}

