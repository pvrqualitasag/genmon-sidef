#!/bin/bash
#' ---
#' title: GenMon localhost Replacement
#' date:  2020-08-31
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Replacement of hostname 'localhost' in php-scripts.
#'
#' ## Description
#' The php-scripts of GenMon contain 'localhost' as their hostname. This has to 
#' be changed for a system that is available through the internet.
#'
#' ## Details
#' All php-scripts in the given php-source directory are searched for the source 
#' name of the hostname. All occurrences of the source name are replaced with the 
#' given target name.
#' 
#' ## Example
#' ./gnm_replace_localhost.sh
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
  $ECHO "Usage: $SCRIPT -p <php_src_directory> -s <host_src_name> -t <host_trg_name>"
  $ECHO "  where -p <php_src_directory>  --  directory with php-source files   (optional)"
  $ECHO "        -s <host_src_name>      --  original hostname to be replaced  (optional)"
  $ECHO "        -t <host_trg_name>      --  target value for hostname         (optional)"
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
PHPSRCDIR=/var/www/html/genmon-ch
HOSTNAMESRC=http://localhost
HOSTNAMETRG=https:fagr.genmon.ch/gnm
while getopts ":p:s:t:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    p)
      PHPSRCDIR=$OPTARG
      ;;
    s)
      HOSTNAMESRC=$OPTARG
      ;;
    t)
      HOSTNAMETRG=$OPTARG
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
if test "$PHPSRCDIR" == ""; then
  usage "-p <php_src_dir> not defined"
fi
if test "$HOSTNAMESRC" == ""; then
  usage "-s <src_hostname> not defined"
fi
if test "$HOSTNAMETRG" == ""; then
  usage "-t <trg_hostname> not defined"
fi


#' ## Replace Source Value for Hostname
#' Go through all php file in source directory and do the replacement
#+ replacement
grep -r "${HOSTNAMESRC}/" $PHPSRCDIR/*.php | cut -d ':' -f1 | sort -u | while read f;
do
  log_msg "$SCRIPT" " * Replacing $HOSTNAMESRC with $HOSTNAMETRG in $f ..."
  mv $f $f.org
  cat $f.org | sed -e "s|${HOSTNAMESRC}|${HOSTNAMETRG}|" > $f
done



#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

