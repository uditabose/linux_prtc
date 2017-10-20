source ../../env.sh
make clean
if make ; then
  ./sign-all.sh
fi
