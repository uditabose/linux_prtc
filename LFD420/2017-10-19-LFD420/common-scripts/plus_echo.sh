#!/bin/bash 

# we'll just prepend a + 
function plus_echo () {
  echo "$PS4$@"
}
