#
#
#   Check Files with PGPORT
#   2021-04-27 (pvr)
#
# ########################################################################### ###

# define constants
RESULTFILE=pg_port_files.txt
PRPREPO=/Users/pvr/Data/Projects/Github/pvrqualitasag/GENMON_Stack/poprep/production

# change to poprep repository
cd $PRPREPO

# init result
echo > $RESULTFILE

# loop over file extensions
for e in pl xml dtd
do 
  echo " * Checking files with extension: $e ..."
  grep -r 5433 * | cut -d ':' -f1 | grep ".${e}$" >> $RESULTFILE
  sleep 2
done


# run replacement
cat $RESULTFILE | while read f
do
  echo " * Replacing port in $f ..."
  sed -i -e "s/5433/__PGPORT__/g" $f
  sleep 2
done

# special file
sed -i -e "s/5433/__PGPORT__/g" apiis/bin/mk_texdocu_modelfile


# remove backup
git status | grep "\-e" | while read f;do echo " * Remove backup file $f ..."; rm -rf $f;sleep 2;done
