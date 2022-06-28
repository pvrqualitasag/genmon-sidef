#!/bin/bash
#' ---
#' title: Post PopRep Analysis
#' date:  2022-06-28 06:34:01
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Post poprep analysis that is usable on the commandline
#'
#' ## Description
#' Run post-poprep analysis to compute all indices used for GenMon
#'
#' ## Details
#' This script is built based on the php-script of GenMon that runs after PopRep
#'
#' ## Example
#' ./post_prp_analysis.sh -b <breed_name> -p <prp_proj>
#'
#' ## Set Directives
#' General behavior of the script is driven by the following settings
#+ bash-env-setting, eval=FALSE
set -o errexit    # exit immediately, if single command exits with non-zero status
set -o nounset    # treat unset variables as errors
set -o pipefail   # return value of pipeline is value of last command to exit with non-zero status
                  #  hence pipe fails if one command in pipe fails


#' ## Global Constants
#' ### Paths to shell tools
#+ shell-tools, eval=FALSE
ECHO=/bin/echo                             # PATH to echo                            #
DATE=/bin/date                             # PATH to date                            #
MKDIR=/bin/mkdir                           # PATH to mkdir                           #
BASENAME=/usr/bin/basename                 # PATH to basename function               #
DIRNAME=/usr/bin/dirname                   # PATH to dirname function                #

#' ### Directories
#' Installation directory of this script
#+ script-directories, eval=FALSE
INSTALLDIR=`$DIRNAME ${BASH_SOURCE[0]}`    # installation dir of bashtools on host   #

#' ### Files
#' This section stores the name of this script and the
#' hostname in a variable. Both variables are important for logfiles to be able to
#' trace back which output was produced by which script and on which server.
#+ script-files, eval=FALSE
SCRIPT=`$BASENAME ${BASH_SOURCE[0]}`       # Set Script Name variable                #
SERVER=`hostname`                          # put hostname of server in variable      #



#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -a <a_example> -b <b_example> -c"
  $ECHO "  where -a <a_example> ..."
  $ECHO "        -b <b_example> (optional) ..."
  $ECHO "        -c (optional) ..."
  $ECHO ""
  exit 1
}

#' ### Start Message
#' The following function produces a start message showing the time
#' when the script started and on which server it was started.
#+ start-msg-fun, eval=FALSE
start_msg () {
  $ECHO "********************************************************************************"
  $ECHO "Starting $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "Server:  $SERVER"
  $ECHO
}

#' ### End Message
#' This function produces a message denoting the end of the script including
#' the time when the script ended. This is important to check whether a script
#' did run successfully to its end.
#+ end-msg-fun, eval=FALSE
end_msg () {
  $ECHO
  $ECHO "End of $SCRIPT at: "`$DATE +"%Y-%m-%d %H:%M:%S"`
  $ECHO "********************************************************************************"
}

#' ### Log Message
#' Log messages formatted similarly to log4r are produced.
#+ log-msg-fun, eval=FALSE
log_msg () {
  local l_CALLER=$1
  local l_MSG=$2
  local l_RIGHTNOW=`$DATE +"%Y%m%d%H%M%S"`
  $ECHO "[${l_RIGHTNOW} -- ${l_CALLER}] $l_MSG"
}


#' ## Main Body of Script
#' The main body of the script starts here with a start script message.
#+ start-msg, eval=FALSE
start_msg

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
breed_short_name=''
breed_long_name=''
PROJNAME=''
while getopts ":b:p:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      breed_short_name=$OPTARG
      ;;
    p)
      PROJNAME=$OPTARG
      ;;
    :)
      usage "-$OPTARG requires an argument"
      ;;
    ?)
      usage "Invalid command line argument (-$OPTARG) found"
      ;;
  esac
done

shift $((OPTIND-1))  #This tells getopts to move on to the next argument.

#' ## Checks for Command Line Arguments
#' The following statements are used to check whether required arguments
#' have been assigned with a non-empty value
#+ argument-test, eval=FALSE
if test "$breed_short_name" == ""; then
  usage "-b breed_short_name required but not defined"
fi
if test "$PROJNAME" == ""; then
  usage "-p <prp_project_name> required but not defined"
fi


#' ## Defaults for Optional Parameters
#' Use meaningful default for optional parameters
#+ param-defaults
if [ "$breed_long_name" == '' ];then
  breed_long_name=$breed_short_name
fi


#' ## PopRep Postanalysis
#' In PopRep post-analysis, all indices for GenMon are computed
#+ prp-post-analysis
# check whether the breed already exists in the table codes
log_msg $SCRIPT " * Check record of breed $breed_short_name in table codes ..."
nr_code_breed=$(psql -U postgres -d GenMon_CH -c "select count(*) from codes where short_name='$breed_short_name'" | tail -3 | head -1)
log_msg $SCRIPT " ** Number of rows for breed $breed_short_name in table codes: $nr_code_breed ..."
# create entry, if none was found
if [ $nr_code_breed -eq 0 ]
then
  # next id
  last_id=$(psql -U postgres -d GenMon_CH -c "select max(db_code) from codes" | tail -3 | head -1)
  $breed_short_name " ** Insert breed $breed_short_name into codes"
  psql -U postgres -d GenMon_CH -c "INSERT INTO codes (short_name, class, long_name, db_code) values ('$breed_short_name', 'BREED', '$breed_long_name', $((last_id+1)))"
fi

# get breed_id for current breed_short_name from table codes
breed_id=$(psql -U postgres -d GenMon_CH -c "select db_code from codes where short_name=$breed_short_name" | tail -3 | head -1)
log_msg $SCRIPT " * Id of breed $breed_short_name: $breed_id ..."


# check whether the breed_id has already a record in the summary table
log_msg $SCRIPT  " * Check record of breed $breed_id in table summary ..."
nr_row_summary=$(psql -U postgres -d GenMon_CH -c "select count(*) from summary where breed_id = $breed_id" | tail -3 | head -1)
log_msg $SCRIPT  " ** Number of rows for breed $breed_id in table summary: $nr_row_summary ..."
if [ $nr_row_summary -eq 0 ]
then
  log_msg $SCRIPT  " ** Inserting record into summary table ..."
  psql -U postgres -d GenMon_CH -c "INSERT INTO summary (breed_id, breed_name, owner, species, public) VALUES ($breed_id, '$breed_short_name', '$user', '$species', $public)"
fi

exit

# transfer most important tables (temp tables are deleted right after)
# check which of the tables exist
echo " * Name of tables to be deleted: "
psql -U postgres -d GenMon_CH -c "select * from pg_catalog.pg_tables where tableowner = 'apiis_admin'"
psql -U postgres -d GenMon_CH -c "select * from pg_catalog.pg_tables where tablename in ('tmp2_table3',
                                                         'breed${breed_id}_inbryear',
                                                        'apiis_admin.tmp2_table3',
                                                        'apiis_admin.breed${breed_id}_inbryear',
                                                        'tmp2_table2',
                                                        'breed${breed_id}_inb_year_sex',
                                                        'apiis_admin.tmp2_table2',
                                                        'apiis_admin.breed${breed_id}_inb_year_sex',
                                                        'tmp2_ne',
                                                        'breed${breed_id}_ne',
                                                        'apiis_admin.tmp2_ne',
                                                        'apiis_admin.breed${breed_id}_ne',
                                                        'tmp2_pedcompl',
                                                        'breed${breed_id}_pedcompl',
                                                        'apiis_admin.tmp2_pedcompl',
                                                        'apiis_admin.breed${breed_id}_pedcompl',
                                                        'tmp2_table5',
                                                        'breed${breed_id}_pedcompl',
                                                        'apiis_admin.tmp2_table5',
                                                        'apiis_admin.breed${breed_id}_ne_deltaf',
                                                        'transfer',
                                                        'breed${breed_id}_transfer',
                                                        'apiis_admin.transfer',
                                                        'apiis_admin.breed${breed_id}_transfer',
                                                        'animal',
                                                        'breed${breed_id}_data',
                                                        'apiis_admin.animal',
                                                        'apiis_admin.breed${breed_id}_data',
                                                        'gene_stuff',
                                                        'tmp1_gen',
                                                        'apiis_admin.gene_stuff',
                                                        'apiis_admin.tmp1_gen')"
                                                        
echo " * Number of tables to be deleted: "
psql -U postgres -d GenMon_CH -c "select count(*) from pg_catalog.pg_tables where tableowner = 'apiis_admin'"
psql -U postgres -d GenMon_CH -c "select count(*) from pg_catalog.pg_tables where tablename in ('tmp2_table3',
                                                        'breed${breed_id}_inbryear',
                                                        'apiis_admin.tmp2_table3',
                                                        'apiis_admin.breed${breed_id}_inbryear',
                                                        'tmp2_table2',
                                                        'breed${breed_id}_inb_year_sex',
                                                        'apiis_admin.tmp2_table2',
                                                        'apiis_admin.breed${breed_id}_inb_year_sex',
                                                        'tmp2_ne',
                                                        'breed${breed_id}_ne',
                                                        'apiis_admin.tmp2_ne',
                                                        'apiis_admin.breed${breed_id}_ne',
                                                        'tmp2_pedcompl',
                                                        'breed${breed_id}_pedcompl',
                                                        'apiis_admin.tmp2_pedcompl',
                                                        'apiis_admin.breed${breed_id}_pedcompl',
                                                        'tmp2_table5',
                                                        'breed${breed_id}_pedcompl',
                                                        'apiis_admin.tmp2_table5',
                                                        'apiis_admin.breed${breed_id}_ne_deltaf',
                                                        'transfer',
                                                        'breed${breed_id}_transfer',
                                                        'apiis_admin.transfer',
                                                        'apiis_admin.breed${breed_id}_transfer',
                                                        'animal',
                                                        'breed${breed_id}_data',
                                                        'apiis_admin.animal',
                                                        'apiis_admin.breed${breed_id}_data',
                                                        'gene_stuff',
                                                        'tmp1_gen',
                                                        'apiis_admin.gene_stuff',
                                                        'apiis_admin.tmp1_gen')"
 
# define different arrays with table names
OLDTABLES=("tmp2_table3" "tmp2_table2" "tmp2_ne" "tmp2_pedcompl" "tmp2_table5" "transfer" "animal")
NEWTABLES=("breed${breed_id}_inbryear" "breed${breed_id}_inb_year_sex" "breed${breed_id}_ne" "breed${breed_id}_pedcompl" "breed${breed_id}_ne_deltaf" "breed${breed_id}_transfer" "breed${breed_id}_data")
COMMONTABLES=( "gene_stuff" "tmp1_gen")
# check number of old and new tables
echo " * Number of old tables: ${#OLDTABLES[@]} ..."
echo " * Number of new tables: ${#NEWTABLES[@]} ..."
if [ ${#OLDTABLES[@]} -ne ${#NEWTABLES[@]} ]
then
  echo " ERROR: number of old and new tables not equal ==> stop"
  exit 1
fi

# loop over table arrays, drop the tables, if they exist
echo " * Dropping tables, if they exist ..."
for (( i=0; i<${#OLDTABLES[@]}; i++))
do
  echo " * index: $i -- old-table: ${OLDTABLES[$i]} -- new-table: ${NEWTABLES[$i]}"
  psql -U postgres -d GenMon_CH -c "DROP TABLE if exists ${OLDTABLES[$i]}"
  psql -U postgres -d GenMon_CH -c "DROP TABLE if exists ${NEWTABLES[$i]}"
  psql -U postgres -d GenMon_CH -c "DROP TABLE if exists apiis_admin.${OLDTABLES[$i]}"
  psql -U postgres -d GenMon_CH -c "DROP TABLE if exists apiis_admin.${NEWTABLES[$i]}"
done
for (( i=0; i<${#COMMONTABLES[@]}; i++))
do
  echo " * index: $i -- common-table: ${COMMONTABLES[$i]}"
  psql -U postgres -d GenMon_CH -c "DROP TABLE if exists ${COMMONTABLES[$i]}"
  psql -U postgres -d GenMon_CH -c "DROP TABLE if exists apiis_admin.${COMMONTABLES[$i]}"
done

# count to check after drop
echo " * Checking tables counts after drop ..."
psql -U postgres -d GenMon_CH -c "select count(*) from pg_catalog.pg_tables where tableowner = 'apiis_admin'"
psql -U postgres -d GenMon_CH -c "select count(*) from pg_catalog.pg_tables where tablename in ('tmp2_table3',
                                                        'breed${breed_id}_inbryear',
                                                        'apiis_admin.tmp2_table3',
                                                        'apiis_admin.breed${breed_id}_inbryear',
                                                        'tmp2_table2',
                                                        'breed${breed_id}_inb_year_sex',
                                                        'apiis_admin.tmp2_table2',
                                                        'apiis_admin.breed${breed_id}_inb_year_sex',
                                                        'tmp2_ne',
                                                        'breed${breed_id}_ne',
                                                        'apiis_admin.tmp2_ne',
                                                        'apiis_admin.breed${breed_id}_ne',
                                                        'tmp2_pedcompl',
                                                        'breed${breed_id}_pedcompl',
                                                        'apiis_admin.tmp2_pedcompl',
                                                        'apiis_admin.breed${breed_id}_pedcompl',
                                                        'tmp2_table5',
                                                        'breed${breed_id}_pedcompl',
                                                        'apiis_admin.tmp2_table5',
                                                        'apiis_admin.breed${breed_id}_ne_deltaf',
                                                        'transfer',
                                                        'breed${breed_id}_transfer',
                                                        'apiis_admin.transfer',
                                                        'apiis_admin.breed${breed_id}_transfer',
                                                        'animal',
                                                        'breed${breed_id}_data',
                                                        'apiis_admin.animal',
                                                        'apiis_admin.breed${breed_id}_data',
                                                        'gene_stuff',
                                                        'tmp1_gen',
                                                        'apiis_admin.gene_stuff',
                                                        'apiis_admin.tmp1_gen')"
 

# run the following commands on the shell
echo " * Dumping tables from poprep project-db ... "
for (( i=0; i<${#OLDTABLES[@]}; i++))
do
  echo " ** pg_dump table: ${OLDTABLES[$i]} ..."
  pg_dump -t ${OLDTABLES[$i]} -U apiis_admin --no-tablespaces -w $PROJNAME | psql -U geome_admin -w GenMon_CH
done
for (( i=0; i<${#COMMONTABLES[@]}; i++))
do
  echo " ** pg_dump table: ${COMMONTABLES[$i]} ..."
  pg_dump -t ${COMMONTABLES[$i]} -U apiis_admin --no-tablespaces -w $PROJNAME | psql -U geome_admin -w GenMon_CH
done


# alter schemas
echo " * Alter schemas of old tables ..."
for (( i=0; i<${#OLDTABLES[@]}; i++))
do
  echo " ** alter schema for table: ${OLDTABLES[$i]} ..."
  psql -U postgres -d GenMon_CH -c "ALTER TABLE apiis_admin.${OLDTABLES[$i]} SET SCHEMA public"
done
for (( i=0; i<${#COMMONTABLES[@]}; i++))
do
  echo " ** alter schema for table: ${COMMONTABLES[$i]} ..."
  psql -U postgres -d GenMon_CH -c "ALTER TABLE apiis_admin.${COMMONTABLES[$i]} SET SCHEMA public"
done


# rename
echo " * Renaming tables ..."
for (( i=0; i<${#OLDTABLES[@]}; i++))
do
  echo " ** rename ${OLDTABLES[$i]} to ${NEWTABLES[$i]} ..."
  psql -U postgres -d GenMon_CH -c "ALTER TABLE ${OLDTABLES[$i]} RENAME TO ${NEWTABLES[$i]}"
done


# rename indices
echo " * Renaming indices ..."
OLDIDX=( "idx_transfer_1" "idx_transfer_2" "uidx_animal_1" "uidx_animal_rowid" "uidx_pk_transfer" "uidx_transfer_rowid")
echo " * Number of old indices: ${#OLDIDX[@]} ..."
NEWIDX=( "idx_transfer_1_${breed_id}" "idx_transfer_2_${breed_id}" "uidx_animal_1_${breed_id}" "uidx_animal_rowid_${breed_id}" "uidx_pk_transfer_${breed_id}" "uidx_transfer_rowid_${breed_id}")
echo " * Number of new indices: ${#NEWIDX[@]} ..."
if [ ${#OLDIDX[@]} -ne ${#NEWIDX[@]} ]
then
  echo " * ERROR: Number of indices do not match ==> stop"
  exit 1
fi
for (( i=0; i<${#OLDIDX[@]}; i++))
do
  echo " ** dropping index: ${NEWIDX[$i]} ..."
  psql -U postgres -d GenMon_CH -c "drop index if exists ${NEWIDX[$i]}"
  echo " ** rename index ${OLDIDX[$i]} to ${NEWIDX[$i]}"
  psql -U postgres -d GenMon_CH -c "ALTER INDEX if exists ${OLDIDX[$i]} RENAME TO ${NEWIDX[$i]}"
done


# change sex codes
echo " * Update sex in breed table ..."
psql -U postgres -d GenMon_CH -c "UPDATE breed${breed_id}_data SET db_sex=2 where db_sex=117"
psql -U postgres -d GenMon_CH -c "UPDATE breed${breed_id}_data SET db_sex=3 where db_sex=118"


# Update MVC values in pedigree
echo " * Change mvc values ..."
COLSMVC=( "plz" "introgression" "inb_gen" "cryo_cons")
for (( i=0; i<${#COLSMVC[@]}; i++))
do
  echo " ** update mvc in column: ${COLSMVC[$i]} ..."
  psql -U postgres -d GenMon_CH -c "update breed${breed_id}_data set ${COLSMVC[$i]}=NULL where ${COLSMVC[$i]}='-9999'"
done


# # Cast column plz to integer to match plz column in other tables
echo " * Cast columns ..."
psql -U postgres -d GenMon_CH -c "alter table breed${breed_id}_data alter column plz TYPE INTEGER USING (plz::integer)"
psql -U postgres -d GenMon_CH -c "alter table breed${breed_id}_data alter column inb_gen TYPE REAL USING (inb_gen::real)"
psql -U postgres -d GenMon_CH -c "alter table breed${breed_id}_data alter column introgression TYPE REAL USING (introgression::real)"


# //Update the effective population size (Ne) table ! To put back
echo " * Update Ne table"
psql -U postgres -d GenMon_CH -c "insert into breed${breed_id}_ne (method) values ('Ne_DeltaFp')"
psql -U postgres -d GenMon_CH -c "update breed${breed_id}_ne set ne=(select avg(ne) from breed${breed_id}_ne_deltaf where year > (select max(year)- (SELECT round(pop,0) FROM tmp1_gen ORDER BY year DESC OFFSET 3 LIMIT 1)  from breed${breed_id}_ne_deltaf)) where method='Ne_DeltaFp'"

 
# //Add the inbreeding to all animals from the animal table
echo " * Inbreeding ..."
psql -U postgres -d GenMon_CH -c "alter table breed${breed_id}_data add column inbreeding real"
psql -U postgres -d GenMon_CH -c "update breed${breed_id}_data set inbreeding = (select i.inbreeding from gene_stuff i where breed${breed_id}_data.db_animal=i.db_animal)"
 
 
# Maximum Year
echo " * Maximum Year ..."
max_year=$(psql -U postgres -d GenMon_CH -c "SELECT distinct max(EXTRACT(YEAR FROM birth_dt)) as max_year FROM breed${breed_id}_data" | tail -3 | head -1)
echo " ** Maximum year: $max_year ..."


# Generation Interval
echo " * Generation Interval ..."
GI=$(psql -U postgres -d GenMon_CH -c "SELECT round(pop,0) FROM tmp1_gen ORDER BY year DESC OFFSET 3 LIMIT 1" | tail -3 | head -1)
echo " ** Generation Interval: $GI ..."


# Breed Inb PLZ Table
echo " * Drop if exists bree_inb_plz table ..."
psql -U postgres -d GenMon_CH -c "DROP TABLE if exists breed${breed_id}_inb_plz"
echo " * Create bree_inb_plz table ..."
psql -U postgres -d GenMon_CH -c "CREATE TABLE breed${breed_id}_inb_plz (plz int references plzo_plz(plz), mean_inb_lastgi real, max_inb_lastgi real, num_ind_lastgi int, mean_inb_gen_lastgi real, mean_introgr_lastgi real)"
echo " * Insert data ..."
psql -U postgres -d GenMon_CH -c "INSERT INTO breed${breed_id}_inb_plz (select plz from plzo_plz)"
echo " * Number of records in table breed${breed_id}_inb_plz ..."
psql -U postgres -d GenMon_CH -c "select count(*) from breed${breed_id}_inb_plz"


# Mean Inbreeding for last GI
echo " * Mean inbreeding ..."
STARTINB=$((max_year-GI))
echo " ** Start Year of inbreeding: $STARTINB ..."
psql -U postgres -d GenMon_CH -c "UPDATE breed${breed_id}_inb_plz SET mean_inb_lastgi = (select q.in from (select avg(bd.inbreeding) as in, bd.plz as p from breed${breed_id}_data bd where extract(year from bd.birth_dt) >= $STARTINB group by bd.plz) q where q.p=breed${breed_id}_inb_plz.plz)"


# Number of individuals in last GI
echo " * Number of individuals ..."
psql -U postgres -d GenMon_CH -c "UPDATE breed${breed_id}_inb_plz SET num_ind_lastgi = (select q.in from (select count(*) as in, bd.plz as p from breed${breed_id}_data bd where extract(year from bd.birth_dt) >= $STARTINB group by bd.plz) q where q.p=breed${breed_id}_inb_plz.plz)"


# Mean Inbreeding from genetic data
echo " * Mean inbreeding from genetic data ..."
psql -U postgres -d GenMon_CH -c "UPDATE breed${breed_id}_inb_plz SET mean_inb_gen_lastgi = (select q.in from (select avg(bd.inb_gen) as in, bd.plz as p from breed${breed_id}_data bd where extract(year from bd.birth_dt) >= $STARTINB group by bd.plz) q where q.p=breed${breed_id}_inb_plz.plz)" 


# Mean Introgression
echo " * Mean introgressen ..."
psql -U postgres -d GenMon_CH -c "UPDATE breed${breed_id}_inb_plz SET mean_introgr_lastgi = (select q.in from (select avg(bd.introgression) as in, bd.plz as p from breed${breed_id}_data bd where extract(year from bd.birth_dt) >= $STARTINB group by bd.plz) q where q.p=breed${breed_id}_inb_plz.plz)"


# Introgression by year
echo " * Introgression by year - Drop table, if exists..."
psql -U postgres -d GenMon_CH -c "DROP TABLE if exists breed${breed_id}_intryear"
echo " * Introgression by year - Create table ..."
psql -U postgres -d GenMon_CH -c "create table breed${breed_id}_intryear as (select q.year, count(*) as num, round(cast(avg(q.introgression) as numeric),3) as av, round(cast(max(q.introgression) as numeric),3) as max, round(cast(min(q.introgression) as numeric),3) as min, round(cast(stddev(q.introgression) as numeric),3) as std from (select extract(year from birth_dt) as year, introgression  from breed${breed_id}_data where introgression is not null) q group by q.year order by q.year)"


# //Update summary table
echo " * First update of summary table"
psql -U postgres -d GenMon_CH -c "SELECT sum(a_avg*number)/sum(number) as inb_avg, sum(number) FROM breed${breed_id}_inbryear WHERE year != 'unknown' and cast(year as integer) >= $STARTINB"
inb_avg=$(psql -U postgres -d GenMon_CH -c "SELECT sum(a_avg*number)/sum(number) as inb_avg FROM breed${breed_id}_inbryear WHERE year != 'unknown' and cast(year as integer) >= $STARTINB" | tail -3 | head -1 | perl -w -e 'my $inb=<>;my $inbr=sprintf("%.4f", $inb);print $inbr')
echo " ** Avg inbreeding: $inb_avg ..."
sum_num_ind=$(psql -U postgres -d GenMon_CH -c "SELECT sum(number) FROM breed${breed_id}_inbryear WHERE year != 'unknown' and cast(year as integer) >= $STARTINB" | tail -3 | head -1)
echo " ** Number of animals: $sum_num_ind ..."

# Compute minimal radius by unrolling the function Min_radius
echo " * Compute minimal radius ..."
echo " * Total number of animals ..."
num_ind_total=$(psql -U postgres -d GenMon_CH -c "select sum(p.num_ind_lastgi) from breed${breed_id}_inb_plz p" | tail -3 | head -1)
echo $num_ind_total

echo " * Write distance table to file"
psql -U postgres -d GenMon_CH -c "select st_distance(st_setsrid(a.wmc,3857), st_setsrid(pc.centroid,3857)) as distance, p.num_ind_lastgi
	from (select st_geomfromtext('POINT(' || sum(st_x(st_setsrid(pc.centroid,3857))*p.num_ind_lastgi)/sum(p.num_ind_lastgi) ||' ' || sum(st_y(st_setsrid(pc.centroid,3857))*p.num_ind_lastgi)/sum(p.num_ind_lastgi) || ')') as wmc
	from (select p1.num_ind_lastgi as num_ind_lastgi, p1.plz as plz from breed${breed_id}_inb_plz p1 where p1.num_ind_lastgi is not null) p, plz_centroid pc where p.plz=pc.plz
	) a, plz_centroid pc, (select * from breed${breed_id}_inb_plz where num_ind_lastgi is not null) p
	where pc.plz=p.plz
	order by distance" > tmp_dist.txt
	
# loop over distance table
NUMINDSUM=0
NUMINDPERCENT=0
MINRADIUS=0
cat tmp_dist.txt | grep -v distance | grep -v "\-\-\-" | grep -v rows | grep -v "^$" | while read l
do 
  #echo " * Line: $l ..."
  DIST=$(echo $l | cut -d '|' -f1);
  NUMIND=$(echo $l | cut -d '|' -f2);
  echo " ** Distance: $DIST -- Num_Ind: $NUMIND"
  NUMINDSUM=$((NUMINDSUM + NUMIND))
  NUMINDPERCENT=$((100 * NUMINDSUM / num_ind_total))
  echo " ** NUMINDSUM: $NUMINDSUM  --  NUMINDPERCENT: $NUMINDPERCENT"
  if [ $NUMINDPERCENT -gt 75 ]
  then
    echo $DIST > tmp_min_dist.txt
    break
  fi
done

min_radius2=$(cat tmp_min_dist.txt | perl -w -e 'my $l = <>;my $dist = sprintf("%.2f", $l / 1000);print $dist')
echo " ** Minimum radius: $min_radius2 ..."

# clean up tmp_dist file
rm tmp_dist.txt
rm tmp_min_dist.txt


# Table with socioec weights
echo " * Table with socioec weights ..."
table_socioec=$(psql -U postgres -d GenMon_CH -c "SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_name LIKE 'plz_socioec_%' ORDER BY table_name DESC LIMIT 1" | tail -3 | head -1)
echo " ** Table name: $table_socioec ..."


# //calculate the trend of number of animals
echo " * Trend of number of animals ..."
max_bd_year=$(psql -U postgres -d GenMon_CH -c "SELECT max(date_part('year',birth_dt)) from breed${breed_id}_data" | tail -3 | head -1)
echo " ** Max bd year: $max_bd_year ..."

# loop over past years and extract number of males and females
if [ -f "tmp_trend_male.txt" ];then rm tmp_trend_male.txt;fi
if [ -f "tmp_trend_female.txt" ];then rm tmp_trend_female.txt;fi
echo " * Loop over years ..."
for (( i=1; i<7; i++))
do
  YEAR=$((max_bd_year - i))
  echo " ** Current year: $YEAR ..."
  NRMALE=$(psql -U postgres -d GenMon_CH -c "SELECT count(*) FROM breed${breed_id}_data WHERE db_sex=2 AND date_part('year', birth_dt)=$YEAR" | tail -3 | head -1)
  echo " ** Number of males: $NRMALE ..."
  NRFEMALE=$(psql -U postgres -d GenMon_CH -c "SELECT count(*) FROM breed${breed_id}_data WHERE db_sex=3 AND date_part('year', birth_dt)=$YEAR" | tail -3 | head -1)
  echo " ** Number of females: $NRFEMALE ..."
  # write number to files
  echo "${YEAR},${NRMALE}" >> tmp_trend_male.txt
  echo "${YEAR},${NRFEMALE}" >> tmp_trend_female.txt
done

# compute the trend
trend_male=$(cat tmp_trend_male.txt | perl -w /home/gnmzws/source/GENMON/FunctionsLinearTrend.pl)
echo " ** Trend males: $trend_male ..."
trend_female=$(cat tmp_trend_female.txt | perl -w /home/gnmzws/source/GENMON/FunctionsLinearTrend.pl)
echo " ** Trend males: $trend_female ..."

# compute the change
# change_male=round(floatval($trend_male["m"])/floatval(end($males))*100,2);
change_male=$((echo -n "${trend_male},";tail -1 tmp_trend_male.txt | cut -d ',' -f2 | sed -e "s/ //") | \
perl -w -e 'my $l = <>;my @tm=split(/,/, $l);my $change=sprintf("%.2f", $tm[0]/$tm[1]*100);print "$change\n"')
echo " ** Change male: $change_male ..."

change_female=$((echo -n "${trend_female},";tail -1 tmp_trend_female.txt | cut -d ',' -f2 | sed -e "s/ //") | \
perl -w -e 'my $l = <>;my @tm=split(/,/, $l);my $change=sprintf("%.2f", $tm[0]/$tm[1]*100);print "$change\n"')
echo " ** Change female: $change_female ..."

# clean up temp files
rm tmp_trend_male.txt
rm tmp_trend_female.txt


# Remaining update of summary table 
echo " * Remaining update of summary table  ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary SET last_year = $max_year where breed_id = $breed_id"
echo " ** set last_year to: $max_year ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary SET avg_inb = $inb_avg where breed_id = $breed_id"
echo " ** set avg_inb to: $inb_avg ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary SET num_ind = $sum_num_ind where breed_id = $breed_id"
echo " ** setting num_ind to: $sum_num_ind ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary SET gi = $GI where breed_id = $breed_id"
echo " ** setting gi to: $GI ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary SET ne=(select ne from breed${breed_id}_ne where method = 'Ne_DeltaFp') where breed_id = $breed_id"

psql -U postgres -d GenMon_CH -c "UPDATE summary SET min_radius = $min_radius2 where breed_id = $breed_id"
echo " ** setting min_radius to: $min_radius2 ..."

echo " * Compute index_socio_eco ..."
index_socio_eco=$(psql -U postgres -d GenMon_CH -c "SELECT round(cast(sum(a.num_ind_lastGI*b.index_socioec)/sum(a.num_ind_lastGI) as numeric),3) FROM breed${breed_id}_inb_plz a, $table_socioec b WHERE a.plz=b.plz" | tail -3 | head -1)
echo " ** index_socio_eco: $index_socio_eco ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary SET index_socio_eco = $index_socio_eco WHERE breed_id = $breed_id" 
echo " ** setting index_socio_eco to: $index_socio_eco ..."


echo " * Compute introgression ..."
introgression=$(psql -U postgres -d GenMon_CH -c "SELECT round(cast(avg(b.introgression) as numeric),3) FROM breed${breed_id}_data b WHERE extract(year from b.birth_dt) >= $STARTINB" | tail -3 | head -1)
echo " ** introgression: $introgression ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary a SET introgression = $introgression WHERE a.breed_id = $breed_id"
echo " ** setting introgression to: $introgression ..."


echo " * Trends for males and females ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary SET trend_males = $change_male WHERE breed_id = $breed_id"
echo " ** setting trend_male to: $change_male ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary SET trend_females = $change_female WHERE breed_id = $breed_id"
echo " ** setting trend_females to: $change_female ..."


echo " * Pedigree completeness ..."
pedcompl=$(psql -U postgres -d GenMon_CH -c "select round(avg(completeness)*100,2) from breed${breed_id}_pedcompl where generation=6 and year::integer>(select max(year::integer) from breed${breed_id}_pedcompl)-(select gi from summary where breed_id = $breed_id)" | tail -3 | head -1)
echo " ** pedigree completeness: $pedcompl ..."
psql -U postgres -d GenMon_CH -c "UPDATE summary SET ped_compl = $pedcompl where breed_id = $breed_id"
echo " ** setting pedigree completeness to: $pedcompl ..."


echo " * Summary table for breed: $breed_id ..."
psql -U postgres -d GenMon_CH -c "select * from summary where breed_id = $breed_id"



#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

