#!/bin/bash
#' ---
#' title: Update Repository genmon_sidef
#' date:  2020-05-10 12:30:51
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless inital pull of the repository genmon_sidef. 
#'
#' ## Description
#' pull the repository genmon_sidef onto a new remote machine.
#'
#' ## Details
#' The repository genmon_sidef is used to install new machines from a remote location. 
#' All tools required for the installation and configuration are contained in this 
#' repository.
#'
#' ## Example
#' ./update_genmon_sidef.sh
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
  $ECHO "Usage: $SCRIPT  -b <branch_reference> -g <github_uri> -n <repo_name> -s <server_name> -u <remote_user>"
  $ECHO "  where -s <server_name>     --  optional, run package update on single server"
  $ECHO "        -b <repo_reference>  --  optional, update to a branch reference"
  $ECHO "        -g <github_uri>      --  optional, specify uri of github repo"
  $ECHO "        -n <repo_name>       --  optional, specify name of repository"
  $ECHO "        -u <remote_user>     --  optional, username of remote user"
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


#' ### Update For a Given Server
#' The following function runs the package update on a
#' specified server.
#+ update-pkg-fun
pull_repo () {
  local l_SERVER=$1
  log_msg 'pull_repo' " ** Running update on $l_SERVER"
  if [ "$REFERENCE" != "" ]
  then
    SSHCMD="cd $REPOPATH;"'
git fetch;    
git checkout origin/'"$REFERENCE"
  else
    SSHCMD="QTSPDIR=$REPOPATH;"' \
git -C "$QTSPDIR" pull https://github.com/pvrqualitasag/quagtsp-sidef.git'
  fi
  log_msg 'pull_repo' " ** SSHCMD: $SSHCMD"
  ssh $REMOTEUSER@$l_SERVER "$SSHCMD"
}


#' ### Update repository on local server
#' In the case, where this script is called from the local server, 
#' then we do not need to use ssh. Furthermore it might be important to check
#' whether we are inside of the container or not.
#+ local-update-repo
local_pull_repo () {
  log_msg 'local_pull_repo' "Running update on $SERVER"
  QTSPDIR=$REPOPATH

  # check whether we are inside of a singularity container
  if [ "$REFERENCE" != "" ]
  then
    git -C "$QTSPDIR" pull "$GHURI" -b "$REFERENCE"
  else
    git -C "$QTSPDIR" pull "$GHURI"
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
REMOTEUSER=quagadmin
SERVERS=(fagr.genmon.ch)
SERVERNAME=""
REFERENCE=""
REPONAME=genmon-sidef
GHURI=https://github.com/pvrqualitasag/${REPONAME}.git
while getopts ":b:g:n:s:u:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      REFERENCE=$OPTARG
      ;;
    g)
      GHURI=$OPTARG
      ;;
    n)
      REPONAME=$OPTARG
      ;;
    s)
      SERVERNAME=$OPTARG
      ;;
    u)
      REMOTEUSER=$OPTARG
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

#' ## Define User-dependent Variables
#' Repository root and repository path depend on the user, hence they are 
#' specified after commandline parsing
REPOROOT=/home/$REMOTEUSER/simg
REPOPATH=$REPOROOT/quagtsp-sidef

#' ## Run Updates
#' Decide whether to run the update on one server or on all servers on the list
if [ "$SERVERNAME" != "" ]
then
  # if this script is called from $SERVERNAME, do local update
  if [ "$SERVERNAME" == "$SERVER" ]
  then
    local_pull_repo
  else
    pull_repo $SERVERNAME
  fi  
else
  for s in ${SERVERS[@]}
  do
    if [ "$s" == "$SERVER" ]
    then
      local_pull_repo
    else
      pull_repo $s
    fi  
    sleep 2
  done
fi

#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

