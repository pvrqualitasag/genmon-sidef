#!/bin/bash
#' ---
#' title: Init PopRep Workingdirectory Infrastructure
#' date:  2020-06-17 17:35:53
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Automated initialisation of PopRep environment.
#'
#' ## Description
#' Working directory infrastructure for running PopRep is initialised.
#'
#' ## Details
#' Running PopRep requires certain directories which are automatically created, if they do not exist. The creation is done in a separate script such that it can be called before starting the singularity container. 
#'
#' ## Example
#' ./init_prp_workdir.sh 
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

#' ### Create Dir 
#' Specified directory is created, if it does not yet exist
#+ check-exist-dir-create-fun
check_exist_dir_create () {
  local l_check_dir=$1
  if [ ! -d "$l_check_dir" ]
  then
    log_msg check_exist_dir_create "CANNOT find directory: $l_check_dir ==> create it ..."
    $MKDIR -p $l_check_dir
  else
    log_msg check_exist_dir_create "FOUND directory: $l_check_dir ..."
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
PRPLOGDIR=${PRPWORKDIR}/prplog
# prp pg-bind directories
PRPBINDROOT=/qualstorzws01/data_projekte/projekte/poprep
PRPINCOMING=${PRPBINDROOT}/incoming
PRPDONE=${PRPBINDROOT}/done
PRPPROJECTS=${PRPBINDROOT}/projects


#' ## Create PRP Working Directory
#' Create PRP working directory, if it does not exist
#+ check-create-tsp-workdir
if [ "$PRPWORKDIR" != "" ]
then
  check_exist_dir_create $PRPWORKDIR
fi
if [ "$PGDATADIR" != "" ]
then
  check_exist_dir_create $PGDATADIR
fi
if [ "$PGLOGDIR" != "" ]
then
  check_exist_dir_create $PGLOGDIR
fi
if [ "$PRPLOGDIR" != "" ]
then
  check_exist_dir_create $PRPLOGDIR
fi
if [ "$PRPINCOMING" != "" ]
then
  check_exist_dir_create $PRPINCOMING
fi
if [ "$PRPDONE" != "" ]
then
  check_exist_dir_create $PRPDONE
fi
if [ "$PRPPROJECTS" != "" ]
then
  check_exist_dir_create $PRPPROJECTS
fi


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

