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
  breed_long_name = $breed_short_name
fi


#' ## PopRep Postanalysis
#' In PopRep post-analysis, all indices for GenMon are computed
#+ prp-post-analysis
# check whether the breed already exists in the table codes
log_msg $SCRIPT " * Check record of breed $breed_short_name in table codes ..."
nr_code_breed=$(psql -U postgres -d GenMon_CH -c "select count(*) from codes where short_name=$breed_short_name" | tail -3 | head -1)
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



#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

