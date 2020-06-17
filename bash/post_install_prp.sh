#!/bin/bash
#' ---
#' title: Post Installation Script for PopRep (PRP)
#' date:  2020-06-17 16:50:02
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Running post-installation tasks required for PopRep (prp) automatically.
#'
#' ## Description
#' All tasks required for running prp that cannot be included in the singularity 
#' recipe file are included in this script. The tasks included in this script are 
#' run by the user that is also running the singularity container instance. 
#'
#' ## Details
#' Tasks required to run after building the singularity container for prp.
#'
#' ## Example
#' ./post_install_prp.sh 
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
  $ECHO "Usage: $SCRIPT"
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

#' ### Check Existence of PRP-Workdir
#' Working directory and substructures are checked. If they do not exist, 
#' an initialisation script is called. 
#+ check-prp-workdir-fun
check_prp_workdir () {
  log_msg 'check_prp_workdir' ' * Check existence of working directory ...'
  if [ ! -d "$PRPWORKDIR" ]
  then
    log_msg 'check_prp_workdir' " ** Create prp-workdir $PRPWORKDIR..."
    $INSTALLDIR/init_prp_workdir.sh
  else
    log_msg 'check_prp_workdir' " ** Found PRP-Workdir $PRPWORKDIR ..."
  fi
}


#' ## Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ## Define Constants 
#' The following constants are specific for the installation environment. 
#' In case the installation must be made flexible, the constants can be 
#' specified as command-line options.
PRPWORKDIR=${HOME}/prp
PGDATADIR=${PRPWORKDIR}/pgdata
PGLOGDIR=${PRPWORKDIR}/pglog
PGLOGFILE=$PGLOGDIR/`date +"%Y%m%d%H%M%S"`_postgres.log
PRPLOGDIR=${PRPWORKDIR}/prplog
PRPLOGFILE=${PRPLOGDIR}/popreport.log

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
# a_example=""
# b_example=""
# c_example=""
# while getopts ":a:b:ch" FLAG; do
#   case $FLAG in
#     h)
#       usage "Help message for $SCRIPT"
#       ;;
#     a)
#       a_example=$OPTARG
# OR for files
#      if test -f $OPTARG; then
#        a_example=$OPTARG
#      else
#        usage "$OPTARG isn't a regular file"
#      fi
# OR for directories
#      if test -d $OPTARG; then
#        a_example=$OPTARG
#      else
#        usage "$OPTARG isn't a directory"
#      fi
#       ;;
#     b)
#       b_example=$OPTARG
#       ;;
#     c)
#       c_example="c_example_value"
#       ;;
#     :)
#       usage "-$OPTARG requires an argument"
#       ;;
#     ?)
#       usage "Invalid command line argument (-$OPTARG) found"
#       ;;
#   esac
# done
# 
# shift $((OPTIND-1))  #This tells getopts to move on to the next argument.


#' ## Check Existence of Workdirectory 
#' Directory infrastructure is checked
#+ check-exist-workdir
check_prp_workdir



#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

