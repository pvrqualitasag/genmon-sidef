#!/bin/bash
#' ---
#' title: Test Process Uploads
#' date:  2020-06-23 14:03:23
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Test Arguments Passing {Write a paragraph about what problems are solved with this script.}
#'
#' ## Description
#' Test passing of arguments based on a sequence of tests scripts. {Write a paragraph about how the problems are solved.}
#'
#' ## Details
#' Tests scripts are simulating the real prp scripts {Give some more details here.}
#'
#' ## Example
#' ./test_process_uploads.sh {Specify an example call of the script.}
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
  $ECHO "Usage: $SCRIPT -i <incoming_dir> -l <log_file> -u <prp_user> -g <prp_grp> -a <apiis_home>"
  $ECHO "  where -i <incoming_dir>  --  incoming directory from where pedigree-data are processed"
  $ECHO "        -l <log_file>      --  logfile for popreport"
  $ECHO "        -u <prp_user>      --  user that runs popreport"
  $ECHO "        -g <prp_grp>       --  group of user that runs popreport"
  $ECHO "        -a <apiis_home>    --  apiis home directory"
  $ECHO "        -b <breed_name>    --  breed name"
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
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
P_INDIR=""
P_LOG=""
P_USER=""
P_GROUP=""
P_APIISHOME=""
BREEDNAME=""
P_PROJ_DIR=""
while getopts ":a:b:i:l:u:g:p:ch" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    a)
      P_APIISHOME=$OPTARG
      ;;
    b)
      BREEDNAME=$OPTARG
      ;;
    i)
      P_INDIR=$OPTARG
      ;;
    l)
      P_LOG=$OPTARG
      ;;
    u)
      P_USER=$OPTARG
      ;;
    g)
      P_GROUP=$OPTARG
      ;;
    p ) 
      P_PROJ_DIR=$OPTARG
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


# some configuration:
INCOMING=${P_INDIR-'/var/lib/postgresql/incoming'}
LOG=${P_LOG-'/var/log/popreport.log'}
USER=${P_USER-'www-data'}
GROUP=${P_GROUP-'popreport'}
APIIS_HOME=${P_APIISHOME-'/home/popreport/production/apiis'}
PROJ_DIR=${P_PROJ_DIR-'/var/lib/postgresql/projects'}
# end configuration
PATH=${APIIS_HOME}/bin:$PATH

HASHES='##############################################################################'
NEXT=`/bin/ls -d ${INCOMING}/20* 2>/dev/null |sort -n |head -1`
DATE=`date +%F-%H.%M.%S`
CPU_NO=`cat /proc/cpuinfo |grep ^processor |wc -l`
HALF=$((${CPU_NO}/2))
if [ $HALF -eq 0 ]; then
    HALF=1
fi

if [ -z "$NEXT" ]; then
    # nothing to do
    exit
fi

WORKING=`/bin/ls -d ${INCOMING}/working* 2>/dev/null |wc -l`
if [ "$WORKING" -ge $HALF ]; then
    exit
fi


#' ## Output Arguments
#' List the arguments
#+ argument-list
log_msg "$SCRIPT" " * INCOMING:    $INCOMING ..."
log_msg "$SCRIPT" " * LOG:         $LOG ..."
log_msg "$SCRIPT" " * PRPUSER:     $PRPUSER ..."
log_msg "$SCRIPT" " * PRPGRP:      $PRPGRP ..."
log_msg "$SCRIPT" " * APIIS_HOME:  $APIIS_HOME ..."
log_msg "$SCRIPT" " * BREEDNAME:   $BREEDNAME ..."
log_msg "$SCRIPT" " * PROJ_DIR:    $PROJ_DIR ..."
log_msg "$SCRIPT" " * NEXT:        $NEXT ..."
log_msg "$SCRIPT" " * WORKING:     $WORKING ..."

if [ ! -d $NEXT ]; then
    echo $HASHES >>$LOG
    echo "${DATE}: Should not happen: $NEXT is not a directory!" >>$LOG
    echo $HASHES >>$LOG
    exit
fi

echo $HASHES >>$LOG
DATE=`date +%F-%H.%M.%S`
echo "${DATE}: processing $NEXT" >>$LOG
STARTDATE=`date "+%F %T"`

BASE=`basename $NEXT`
DATA="${INCOMING}/working_$BASE"
mv $NEXT $DATA
echo "startdate=${STARTDATE}" >>"${DATA}/param"

# for later use:
BASE2=`basename $DATA`
BASE3=`echo $BASE2 |sed -e 's/working_//'`
DONE="${INCOMING}/done_$BASE3"

/bin/chmod -R 0770 $DATA
/bin/chown -R ${USER}:${GROUP} $DATA

EMAIL=`grep ^email= ${DATA}/param  | sed -e 's/^email=//'`
BREED=`grep ^breed= ${DATA}/param  | sed -e 's/^breed=//'`
MALE=`grep ^male= ${DATA}/param  | sed -e 's/^male=//'`
FEMALE=`grep ^female= ${DATA}/param  | sed -e 's/^female=//'`
DATEFORMAT=`grep ^dateformat= ${DATA}/param  | sed -e 's/^dateformat=//'`
DATESEP=`grep ^datesep= ${DATA}/param  | sed -e 's/^datesep=//'`
GETTAR=`grep ^get_tar= ${DATA}/param  | sed -e 's/^get_tar=//'`

# remove special characters:
BREED=`echo $BREED |tr -cd '[:alnum:]'`
# BREED=`echo $BREED |tr -cd '[:graph:]'`  # läßt noch () durch, was die Shell verwirrt
# BREED=`echo $BREED |tr -s '$üÜöÖäÄß ()[]{}' '.'`
MALE=`echo $MALE |tr -s '$üÜöÖäÄß ()[]{}' '.'`
FEMALE=`echo $FEMALE |tr -s '$üÜöÖäÄß ()[]{}' '.'`

if [ "$GETTAR" == "yes" ]; then
    TAR="-g on"
fi
if [ -n "$DATESEP" ]; then
    DATESEP="-s $DATESEP"
fi

echo "Now running run_popreport_file ...." >>$LOG
echo "PATH: $PATH " >> $LOG
echo "APIIS_HOME: $APIIS_HOME " >> $LOG
echo "DATA: $DATA " >> $LOG
#. $APIIS_HOME/bin/run_popreport_file \
#    -b "$BREED" \
#    -d ${DATA}/datafile \
#    -m "$MALE" \
#    -f "$FEMALE" \
#    -y $DATEFORMAT $DATESEP \
#    -e $EMAIL $TAR \
#    -I $DATA \
#    -P $PROJ_DIR \
#    -D >>$LOG 2>&1
$INSTALLDIR/test_run_popreport_file -b "$BREED" -d "${DATA}/datafile" -m "$MALE" -f "$FEMALE" -y $DATEFORMAT $DATESEP -e $EMAIL $TAR -I $DATA -P $PROJ_DIR -D >>$LOG 2>&1
# PARAMS="-b \"$BREED\" -d ${DATA}/datafile -m \"$MALE\" -f \"$FEMALE\" -y $DATEFORMAT $DATESEP -e $EMAIL $TAR -I $DATA -D"
# EXE="$APIIS_HOME/bin/run_popreport_file"
# su -s /bin/bash -lc "$EXE $PARAMS" popreport
echo "Running run_popreport_file done" >>$LOG

mv $DATA $DONE

#' ## Call test-run-prp
#' Call the test-version of run_popreport_file
#+ test-run-prp


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

