if [ -f ../../env.sh ]; then
  source ../../env.sh
fi
source ./local-config.mak

echo "================================================"
echo "+ ./${PROJECT_NAME} 2 3"
./${PROJECT_NAME} 2 3

echo "================================================"
echo "+ ./${PROJECT_NAME} 2 1"
./${PROJECT_NAME} 2 1
echo "================================================"

echo "+ try with strace"
if [[ $1 != "DONT_WAIT" ]]; then
  echo "+ press <ENTER> to go on"
  read r
fi
echo "================================================"
echo "+ strace ./${PROJECT_NAME} 0 10"
strace ./${PROJECT_NAME} 0 10
