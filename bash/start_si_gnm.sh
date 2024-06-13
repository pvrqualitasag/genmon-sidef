#!/bin/bash
#' ---
#' title: Start GenMon Singularity Container
#' date:  2021-04-15 16:12:39
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless start of instance of GenMon singularity container alone
#'
#' ## Description
#' Start only an instance of the GenMon Singularity Container
#'
#' ## Details
#' This does not start the pg-database nor the webserver
#'
#' ## Example
#' ./start_si_gnm.sh -i sicntgnm -n si_gnm.sif
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
  $ECHO "Usage: $SCRIPT -a <gnm_admin_home> -b <bind_path> -i <simg_instance_name> -n <simg_image_file> -w <network_args>"
  $ECHO "  where -a <gnm_admin_home>      --  path to the home directory of the gnm admin ..."
  $ECHO "        -b <bind_path>           --  bindpath for the started instance ..."
  $ECHO "        -i <simg_instance_name>  --  name of the instance to be started ..."
  $ECHO "        -n <simg_image_file>     --  name of the image file from where instance is started ..."
  $ECHO "        -p <parameter_config>    --  (optional) genmon configuration parameter file"
  $ECHO "        -w <network_args>        --  network arguments for the singularity container"
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

#' ### Singularity Instance Check
#' Check whether singularity instance is running
#+ check-singularity-instance-running-fun
check_singularity_instance_running () {
  log_msg 'check_singularity_instance_running' " ** Check status of singularity instance $SINGULARITYINSTANCENAME ..." 
  if [ `sudo singularity instance list | grep $SINGULARITYINSTANCENAME | wc -l` -ne 0 ]
  then
    log_msg 'check_singularity_instance_running' " ** ERROR singularity instance $SINGULARITYINSTANCENAME already running ..."
    exit 1
  else
    log_msg 'check_singularity_instance_running' " ** Singularity instance $SINGULARITYINSTANCENAME not running ..." 
  fi
}

#' ### Check for Existence of Bind Directories on Host
#' Bind directories on host must exist, before container instance can be started with bind-path
#+ check-exist-host-bind-dir-fun
check_exist_host_bind_dir () {
  if [ ! -d "$BINDROOTHOST" ]
  then
    log_msg "check_exist_host_bind_dir" " * Cannot find directory for BINDROOTHOST: $BINDROOTHOST ... create it ..."
    mkdir -p $BINDROOTHOST
  fi
  # check whether all binds on host exist
  echo $BINDPATH | sed -e "s/,/\n/g" | while read p
  do 
    log_msg "check_exist_host_bind_dir" " * Checking path-map: $p ..."
    if [ $(echo "$p" | grep ':' | wc -l) -ne 0 ]
    then
      HOSTPATH=$(echo $p | cut -d':' -f1)
      log_msg "check_exist_host_bind_dir" " ** Checking host path: $HOSTPATH ..."
      if [ ! -d "$HOSTPATH" ]
      then
        log_msg "check_exist_host_bind_dir" " *** Create $HOSTPATH ..."
        mkdir -p $HOSTPATH
      fi
    fi
    sleep 2
  done
  
}


#' ## Main Body of Script
#' The main body of the script starts here with a start script message.
#+ start-msg, eval=FALSE
start_msg

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
SINGULARITYINSTANCENAME='gnmcnt2024'
GNMADMINHOME=${HOME}
SIFLINK=$GNMADMINHOME/simg/img/genmon/gnm.sif
BINDROOTHOST=$GNMADMINHOME/gnm/bindroot
BINDROOTCNTRPG=/var/lib/postgresql
BINDROOTCNTRAPIIS=/home/popreport/production/apiis/var/log
BINDROOTCNTRVARRUNPG=/var/run/postgresql
BINDROOTCNTRDATAFILE=/var/www/html/genmon-ch/Data_files
BINDPATH="$BINDROOTHOST/incoming/:$BINDROOTCNTRPG/incoming,$BINDROOTHOST/done:$BINDROOTCNTRPG/done,$BINDROOTHOST/projects:$BINDROOTCNTRPG/projects,$BINDROOTHOST/log:$BINDROOTCNTRAPIIS,$BINDROOTHOST/run:$BINDROOTCNTRVARRUNPG,$BINDROOTHOST/Data_files:$BINDROOTCNTRDATAFILE,$GNMADMINHOME"
NETWORKARGS=''
PARAMFILE=''
while getopts ":a:b:i:n:p:w:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    a)
      GNMADMINHOME=$OPTARG
      ;;
    b)
      BINDPATH=$OPTARG
      ;;
    i)
      SINGULARITYINSTANCENAME=$OPTARG
      ;;
    n)
      if test -f $OPTARG; then
        SIFLINK=$OPTARG
      else
        usage "$OPTARG isn't a valid singularity image file"
      fi
      ;;
    p)
      PARAMFILE=$OPTARG
      ;;
    w)  
      NETWORKARGS=$OPTARG
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
if test "$SINGULARITYINSTANCENAME" == ""; then
  usage "-i <singularity_instance_name> not defined"
fi
if test "$SIFLINK" == ""; then
  usage "-n <singularity_image_name> not defined"
fi


#' ## Check Status of Instance
#' First check that the instance is not already running
#+ check-instance-running
log_msg "$SCRIPT" ' * Check whether singularity instance is running ...'
check_singularity_instance_running


#' ##  Extended Arguments List
#' Depending on the options given, the arguments are extended
#+ extend-args
EXTENDEDARG=''
if [ "$BINDPATH" != '' ]
then
  # check whether bind root exists
  check_exist_host_bind_dir
  EXTENDEDARG="--bind $BINDPATH"
fi
if [ "$NETWORKARGS" != '' ]
then
  EXTENDEDARG="$EXTENDEDARG --net --network-args $NETWORKARGS"
fi

#' ## Start Singularity Instance
#' Singularity instance is started
#+ singularity-instance-start
log_msg "$SCRIPT" " * Starting instance $SINGULARITYINSTANCENAME from image $SIFLINK with $EXTENDEDARG ..."
sudo singularity instance start --writable-tmpfs $EXTENDEDARG $SIFLINK $SINGULARITYINSTANCENAME


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

