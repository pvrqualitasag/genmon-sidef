#!/bin/bash
#' ---
#' title: Create a List of Poprep / APIIS Bin Links
#' date:  2020-07-08 07:29:57
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless generation of links in poprep/apiis bin.
#'
#' ## Description
#' The poprep sources contain a number of links. These are lost when copying the sources into the container with the %files directive in the singularity definition file. This script produces the list of links based on the source directory outside of the singularity container.
#'
#' ## Details
#' Given a source directory, find -type l is used to produce a list of softlinks. The output of readlink is used to determine the link targets.
#'
#' ## Example
#' ./create_lnk_list.sh -s ~/source/prprepo/home/popreport/production/apiis/bin -o apiis_bin_links.txt -p /home/popreport/production/apiis/bin
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
  $ECHO "Usage: $SCRIPT -o <output_file> -p <path_prefix> -s <source_directory>"
  $ECHO "  where -o <output_file>       --  output file to which list of links is written"
  $ECHO "        -p <path_prefix>       --  path prefix to be added to link source"
  $ECHO "        -s <source_directory>  --  source directory from where links should be found"
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
OUTPUTPATH="/home/quagadmin/source/prprepo/popreport/production/apiis_home_links.txt"
PATHPREFIX="/home/popreport/production/apiis/bin"
SOURCEPATH="/home/quagadmin/source/prprepo/home/popreport/production/apiis/bin"
while getopts ":o:p:s:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    o)
      OUTPUTPATH=$OPTARG
      ;;
    p)
      PATHPREFIX=$OPTARG
      ;;
    s)
      SOURCEPATH=$OPTARG
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
if test "$OUTPUTPATH" == ""; then
  usage "-o <output_path> not defined"
fi
if test "$PATHPREFIX" == ""; then
  usage "-p <prefix_path> not defined"
fi
if test "$SOURCEPATH" == ""; then
  usage "-s <source_path> not defined"
fi


#' ## Clean up 
#' Because list of links is appended to output path, it must be cleaned up
#' first, if it exists
#+ clean-up
if [ -f "$OUTPUTPATH" ]
then
  log_msg "$SCRIPT" " * Clean up existing $OUTPUTPATH ..."
  rm $OUTPUTPATH
fi


#' ## Find Links
#' Links in the directory $SOURCEPATH are found and written to the ouput_path
#+ find-links
find $SOURCEPATH -type l -print | while read e
do 
  log_msg "$SCRIPT" " * Readlink for $e ..."
  lnsrc=${PATHPREFIX}/$(basename $e)
  (echo -n $lnsrc;echo -n ' ';readlink $e) >> $OUTPUTPATH
  sleep 2
done


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

