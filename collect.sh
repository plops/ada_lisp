for i in `find obj_prove/gnatprove/gnatprove.out app doc docs proofs scripts src tests *.* -type f`; do echo "# start of "$i;cat $i;done
