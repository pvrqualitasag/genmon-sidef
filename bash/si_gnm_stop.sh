#!/bin/bash
#' ---
#' title: Stop Singularity Container Instance for GenMon
#' date:  2020-08-10 11:06:33
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless stopping of a singularity container instance that is running GenMon.
#'
#' ## Description
#' Stopping a singularity container image that runs the GenMon system.
#'
#' ## Details
#' For a clean shutdown procedure, first all components of GenMon are stopped, then the singularity instance is stopped. 
#'
#' ## Example
#' ./si_gnm_stop.sh -i signm
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
  $ECHO "Usage: $SCRIPT -i <singularity_instance_name>"
  $ECHO "  where -i <singularity_instance_name>  --  specify singularity instance name to be stopped"
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
SINGULARITYINSTANCENAME='signm'
while getopts ":i:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    i)
      SINGULARITYINSTANCENAME=$OPTARG
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
if test "$SINGULARITYINSTANCENAME" == ""; then
  usage "-i <singularity_instance_name not defined"
fi


#' ## Check Outside of Container 
#' Checking that we are outside of container
#+ check-outside-container
if [ `env | grep SINGULARITY | wc -l` -ne 0 ]
then
  usage " *** ERROR: Cannot run script inside of container"
fi


#' ## Stop Apache
#' Apache webserver inside of container is stopped
#+ stop-www
log_msg "$SCRIPT" ' * Stopping the apache ...'
sudo singularity exec instance://$SINGULARITYINSTANCENAME /usr/sbin/apache2ctl stop
sleep 2

#' ## Stop the PostgreSQL DB-Server
#' Before stopping the singularity instance, we stop the pg-db-server
#+ stop-pg-db-server
log_msg "$SCRIPT" ' * Stopping the postgresql db-server ...'
sudo singularity exec instance://$SINGULARITYINSTANCENAME $INSTALLDIR/gnm_pg_stop.sh
sleep 2


#' ## Stop the Singularity Instance
#' The singualrity instance is stopped
#+ singularity-instance-stop
log_msg "$SCRIPT" " * Stopping the singularity instance $SINGULARITYINSTANCENAME ..."
sudo singularity instance stop $SINGULARITYINSTANCENAME


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

