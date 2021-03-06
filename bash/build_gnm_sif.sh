#!/bin/bash
#' ---
#' title: Build GenMon Singularity Container Image
#' date:  2021-01-26 16:51:57
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless build and deploy of a new container image
#'
#' ## Description
#' Build a singularity image file based on a given definition file
#'
#' ## Details
#' The build script runs the build of a singularity image file (sif) or 
#' of a sandbox directory, depending on the commandline arguments given.  
#' The option -f <sif_path> builds a sif under the path given by <sif_path>. 
#' When giving the option -s <sandbox_dir> a sandbox installation is done 
#' under the directory <sandbox_dir>. When neither of the options -f nor -s 
#' is specified, then a sif under a default path (/home/${USER}/simg/img/genmon/${TDATE}_gnm.sif)
#' is built. 
#' The specification of the argument -l allows to directly create a link 
#' to the .sif file built. This works best, when both the path to the sif  
#' file and the link are given by absolute paths.
#'
#' ## Example
#' ./build_gnm_sif.sh -d <simg_def_file>
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
  $ECHO "Usage: $SCRIPT -d <def_file> -f <singularity_image_file> -l <link_to_sif> -p <parameter_config> -s <sandbox_dir>"
  $ECHO "  where -d <def_file>                --  singularity definition file ..."
  $ECHO "        -f <singularity_image_file>  --  (optional) path to singularity image file"
  $ECHO "        -l <link_to_sif>             --  (optional) link to created singularity image file"
  $ECHO "        -p <parameter_config>        --  (optional) genmon configuration parameter file"
  $ECHO "        -s <sandbox_dir>             --  (optional) path to singularity sandbox directory"
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

#' ### Build Singularity Image File
#' Run a singularity image build
#+ singularity-build-image-fun
singularity_build_image () {
  SIFDIR=$(dirname $SIFPATH)
  if [ ! -d "$SIFDIR" ]
  then 
    log_msg "singularity_build_image" " * Creating $SIFDIR ..."
    mkdir -p $SIFDIR
  fi  
  log_msg "singularity_build_image" " * Building from singularity definition: $SIMGDEF to image path: $SIFPATH ..."
  sudo singularity build $SIFPATH $SIMGDEF
  # add link
  if [ "$SIFLINK" != '' ]
  then
    if [ -e "$SIFLINK" ]
    then
      log_msg "$SCRIPT" " * Removing existing link: $SIFLINK ..."
      rm $SIFLINK
    fi
    log_msg "singularity_build_image" " * Adding link from $SIFPATH to $SIFLINK ..."
    ln -s $SIFPATH $SIFLINK
  fi  
}

#' ### Build Singularity Sandbox
#' Build singularity container in a sandbox directory
#+ singularity-build-sandbox-fun
singularity_build_sandbox () {
  log_msg "singularity_build_sandbox" " * Building from singularity definition: $SIMGDEF to sandbox directory: $SBDIR ..."
  sudo singularity build --sandbox $SBDIR $SIMGDEF  
}

#' ### Replace PGPORT Place Holder
#' Replace the placeholder for PGPORT in $SIMGDEF 
#+ replace-pg-port-fun
replace_pg_port () {
  log_msg "replace_pg_port" " * Replace PGPORT placeholder with $NEWPGPORT in $SIMGDEF ..."
  sed -i -e "s/___PGPORT___/$NEWPGPORT/g" $SIMGDEF
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
SIMGDEF=''
TDATE=$(date +"%Y%m%d%H%M%S")
GNMADMINHOME=${HOME}
SIFPATH="${GNMADMINHOME}/simg/img/genmon/${TDATE}_gnm.sif"
SIFDIR=$(dirname $SIFPATH)
SIFLINK="${GNMADMINHOME}/simg/img/genmon/gnm.sif"
SBDIR=''
NEWPGPORT=''
PARAMFILE=''
while getopts ":d:f:l:p:s:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    d)
      if test -f $OPTARG; then
        SIMGDEF=$OPTARG
      else
        usage " *** ERROR: CANNOT FIND singularity definition file: $OPTARG ..."
      fi
      ;;
    f)
      SIFPATH=$OPTARG
      ;;
    l)
      SIFLINK=$OPTARG
      ;;
    p)
      PARAMFILE=$OPTARG
      ;;
    s)
      SBDIR=$OPTARG
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


#' ## Read Parameter Input
#' If a parameter file is specified we read the input
if [ "$PARAMFILE" != '' ]
then
  log_msg "$SCRIPT" " * Reading input from $PARAMFILE ..."
  source $PARAMFILE
fi


#' ## Checks for Command Line Arguments
#' The following statements are used to check whether required arguments
#' have been assigned with a non-empty value
#+ argument-test, eval=FALSE
if test "$SIMGDEF" == ""; then
  usage "-d <def_file> not defined"
fi


#' ## Replace PGPORT
#' Replace the placeholder in $SIMGDEF for the postgres port PGPORT
if [ "$NEWPGPORT" != '' ]
then
  log_msg "$SCRIPT" " * Replace PGPORT placeholder in $SIMGDEF ..."
  replace_pg_port
fi


#' ## Run Singularity Build
#' Depending on option run the build command
#+ simg-build
if [ "$SIFPATH" != '' ]
then
  singularity_build_image
elif [ "$SBDIR" != '' ]
then
  singularity_build_sandbox
else
  usage "either -f <singularity_image_file> or -s <sandbox_dir> must be defined"
fi


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

