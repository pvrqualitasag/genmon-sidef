#!/bin/bash
#' ---
#' title: Start Singularity Container Instance For PopRep
#' date:  2020-06-18 16:28:18
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Try to start singularity container image and pg-db for PopRep in one step.
#'
#' ## Description
#' Starting a singularity container image that is running a postgresql-db for PopRep.
#'
#' ## Details
#' After starting the singularity container image, the pg-db-server is also started which makes it possible to have the complete PopRep functionality available immediately after the start of the instance.
#'
#' ## Example
#' ./si_prp_start.sh -i siprp -n /home/quagadmin/simg/img/poprep/prp.simg
#'
#' ## Set Directives
#' General behavior of the script is driven by the following settings
#+ bash-env-setting, eval=FALSE
#set -o errexit    # exit immediately, if single command exits with non-zero status
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
  $ECHO "Usage: $SCRIPT -i <singularity_instance_name> -n <singularity_image_name> -b <bind_path>"
  $ECHO "  where -i <singularity_instance_name>  --  specify singularity instance name"
  $ECHO "        -n <singularity_image_name>     --  specify singularity image name"
  $ECHO "        -b <bind_path>                  --  specify bind path (optional)"
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
SINGULAIRTYINSTANCENAME='siprp'
SINGULARITYIMAGENAME=/home/quagadmin/simg/img/poprep/prp.simg
BINDPATH=''
while getopts ":b:i:n:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      BINDPATH=$OPTARG
      ;;
    i)
      SINGULAIRTYINSTANCENAME=$OPTARG
      ;;
    n)
      if test -f $OPTARG; then
        SINGULARITYIMAGENAME=$OPTARG
      else
        usage "$OPTARG isn't a valid singularity image file"
      fi
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
if test "$SINGULAIRTYINSTANCENAME" == ""; then
  usage "-i <singularity_instance_name> not defined"
fi
if test "$SINGULARITYIMAGENAME" == ""; then
  usage "-n <singularity_image_name> not defined"
fi


#' ## Start Singularity Instance
#' Singularity instance is started
#+ singularity-instance-start
if [ "$BINDPATH" == '' ]
then
  log_msg "$SCRIPT" " * Starting singularity instance $SINGULAIRTYINSTANCENAME from image $SINGULARITYIMAGENAME ..."
  singularity instance start $SINGULARITYIMAGENAME $SINGULAIRTYINSTANCENAME
else
  log_msg "$SCRIPT" " * Starting singularity instance $SINGULAIRTYINSTANCENAME from image $SINGULARITYIMAGENAME using bind-path $BINDPATH ..."
  singularity instance start --bind $BINDPATH $SINGULARITYIMAGENAME $SINGULAIRTYINSTANCENAME
fi


#' ## Start PostgreSQL DB-Server
#' The pg-db inside the image is started using the start script
#+ pg-db-start
log_msg "$SCRIPT" " * Starting pg-db ..."
singularity exec instance://$SINGULAIRTYINSTANCENAME $INSTALLDIR/pg_start.sh


#' ## Check Status of DB-Server
#' Using the pg-command to check whether the DB-server is running
#+ pg-db-check
singularity exec instance://$SINGULAIRTYINSTANCENAME /usr/lib/postgresql/10/bin/pg_isready


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

