HERE=$(pwd)

for file in *; do
   if [ -d $file ]; then
      cd $file
      echo "--> $file"
      ./01_genmake.sh
      sudo ./10_clean.sh
      cd ..
      echo "<-- $file"
   fi
done

#cd s_09/extra-stuff/
#
#for file in *; do
#   if [ -d $file ]; then
#      cd $file
#      echo "--> $file"
#      ./01_genmake.sh
#      sudo ./10_clean.sh
#      cd ..
#      echo "<-- $file"
#   fi
#done

cd ${HERE}
