#!/bin/bash
#' ---
#' title: Init Genmon Working Directories
#' date:  2020-08-06 16:02:52
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless preparation of all working directories required by the genmon container.
#'
#' ## Description
#' Working directories on the host where the genmon container is running are checked and created if they are missing. 
#'
#' ## Details
#' The directories are required by postgresql and by genmon. 
#'
#' ## Example
#' ./init_gnm_workdir.sh 
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
  $ECHO "Usage: $SCRIPT -d"
  $ECHO "  where -d  --  run script in dry-run mode ..."
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

#' ### Create Dir 
#' Specified directory is created, if it does not yet exist
#+ check-exist-dir-create-fun
check_exist_dir_create () {
  local l_check_dir=$1
  if [ ! -d "$l_check_dir" ]
  then
    if [ "$DRYRUN" == "TRUE" ]
    then
      log_msg check_exist_dir_create "CANNOT find directory: $l_check_dir ==> create it (DRYRUN) ..."
    else
      log_msg check_exist_dir_create "CANNOT find directory: $l_check_dir ==> create it ..."
      $MKDIR -p $l_check_dir
    fi  
  else
    log_msg check_exist_dir_create "FOUND directory: $l_check_dir ..."
  fi  

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
DRYRUN=""
while getopts ":dh" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      DRYRUN='TRUE'
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

#' ## Define Constants 
#' The following constants are specific for the installation environment. 
#' In case the installation must be made flexible, the constants can be 
#' specified as command-line options.
GNMWORKDIR=${HOME}/gnm
PGDATADIR=${GNMWORKDIR}/pgdata
PGLOGDIR=${GNMWORKDIR}/pglog
GNMLOGDIR=${GNMWORKDIR}/gnmlog
# gnm pg-bind directories
GNMBINDROOT=/qualstorzws01/data_projekte/projekte/genmon
GNMINCOMING=${GNMBINDROOT}/incoming
GNMDONE=${GNMBINDROOT}/done
GNMPROJECTS=${GNMBINDROOT}/projects


#' ## Create GNM Working Directory
#' Create GNM working directory, if it does not exist
#+ check-create-tsp-workdir
if [ "$GNMWORKDIR" != "" ]
then
  check_exist_dir_create $GNMWORKDIR
fi
if [ "$PGDATADIR" != "" ]
then
  check_exist_dir_create $PGDATADIR
fi
if [ "$PGLOGDIR" != "" ]
then
  check_exist_dir_create $PGLOGDIR
fi
if [ "$GNMLOGDIR" != "" ]
then
  check_exist_dir_create $GNMLOGDIR
fi
if [ "$GNMINCOMING" != "" ]
then
  check_exist_dir_create $GNMINCOMING
fi
if [ "$GNMDONE" != "" ]
then
  check_exist_dir_create $GNMDONE
fi
if [ "$GNMPROJECTS" != "" ]
then
  check_exist_dir_create $GNMPROJECTS
fi




#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

