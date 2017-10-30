source common.sh

plusplus_echo 'ls'

find | grep test.sh
find | egrep test.sh
find | color_grep test.sh
find | ${GREP} test.sh

plus_echo_red "red"
plus_echo "neutral"
plus_echo_green "green"
plus_echo "neutral"
