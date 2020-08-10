#!/bin/bash
#' ---
#' title: Cleaning Up PopRep Projects
#' date:  2020-07-09 07:17:56
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless cleaning up of old projects.
#'
#' ## Description
#' Cleaning up all directories used by PopRep. 
#'
#' ## Details
#' Due to security, this script deletes project files only, if we are outside of 
#' the singularity instance and, if the instance siprp is stopped.
#'
#' ## Example
#' ./cleanup_prp.sh 
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

#' ### Check Outside Instance
#' The output of the env function is grepped for the key word SINGULARITY 
#' to check whether we are inside or outside of the singularity instance
#+ check-outside-instance-fun
check_outside_instance () {
  if [ `env | grep SINGULARITY | wc -l` -ne 0 ]
  then
    log_msg 'check_outside_instance' ' ** Inside of instance according to env ...'
    usage " * $SCRIPT cannot run inside of a container instance ..."
  fi
  
}

#' ### Check Running State of Instance siprp
#' Grepping the output of singularity instance list for siprp
#+ check-siprp-stopped-fun
check_siprp_stopped () {
  if [ `singularity instance list | grep siprp | wc -l` -ne 0 ]
  then
    log_msg 'check_siprp_stopped' ' ** Instance siprp seams to run ...'
    usage " * $SCRIPT cannot run, if instance siprp is still running ..."
  fi
  
}

#' ### Cleaning up PopRep Directories
#'
#+ cleanup-prp-dir-fun
cleanup_prp_dir () {
  # project
  log_msg 'cleanup_prp_dir' " ** Cleaning up project dirs under: $prp_proj_root ..."
  for p in ${prp_proj_dirs[@]}
  do
    if [ -d "$prp_proj_root/$p" ]
    then
      log_msg 'cleanup_prp_dir' " *** Cleaning up dir: $prp_proj_root/$p ..."
      rm -rf $prp_proj_root/$p/*
    else
      log_msg 'cleanup_prp_dir' " *** Cannot find: $prp_proj_root/$p ..."
    fi
  done
  # work dir
  log_msg 'cleanup_prp_dir' " ** Cleaning up woring dirs under: $prp_wd_root ..."
  for p in ${prp_wd_dirs[@]}
  do
    if [ -d "$prp_wd_root/$p" ]
    then
      log_msg 'cleanup_prp_dir' " *** Cleaning up dir: $prp_wd_root/$p ..."
      rm -rf $prp_wd_root/$p/*
    else
      log_msg 'cleanup_prp_dir' " *** Cannot find: $prp_wd_root/$p ..."
    fi
  done
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
prp_proj_root=/qualstorzws01/data_projekte/projekte/poprep
prp_proj_dirs=(projects incoming log) 
prp_wd_root=/home/zws/prp
prp_wd_dirs=(pgdata pglog prplog)


#' ## Check Outside of Instance
#' Check whether we are outside of the singularity instance 
#+ check-outside
log_msg "$SCRIPT" ' * Check whether we are outside of singularity instance ...'
check_outside_instance


#' ## Check Instance Stopped
#' This script runs only if instance siprp is stopped
#+ check-instance-stopped
log_msg "$SCRIPT" ' * Check whether instance siprp is stopped ...'
check_siprp_stopped


#' ## Cleanup Log and Project Directories
#' Cleaning up log directories and project directories of PopRep
log_msg "$SCRIPT" ' * Cleaning up PopRep directories ...'
cleanup_prp_dir



#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

