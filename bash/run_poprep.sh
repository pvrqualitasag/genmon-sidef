#!/bin/bash
#' ---
#' title: Run PopRep
#' date:  2020-06-22 11:30:58
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Provide a commandline interfact to poprep
#'
#' ## Description
#' The poprep-program is to be run from commandline. This script prepares all the requirement such that poprep can be executed as shown in PopRep.php from GenMon.
#'
#' ## Details
#' The preparation consists of specifying the parameters that are passed by the webinterface into a file called 'param'.
#'
#' ## Example
#' ./run_poprep.sh -b test_breed -d test_pedigree.ped 
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
  $ECHO "Usage: $SCRIPT -b <breed_name> -p <pedigree_data_file> -e <email_address> -m <male_char> -f <female_char> -d <date_format> -s <data_sep> -i <incoming_dir>"
  $ECHO "  where -b <breed_name>          --  name of the breed"
  $ECHO "        -p <pedigree_data_file>  --  pedigree data file of the breed to be analysed"
  $ECHO "        -e <email_address>       --  e-mail address"
  $ECHO "        -m <male_char>           --  character representing male individual in pedigree"
  $ECHO "        -f <female_char>         --  character representing female individual in pedigree"
  $ECHO "        -d <date_format>         --  format for dates in pedigree"
  $ECHO "        -s <date_sep>            --  separator character for dates in pedigree"
  $ECHO "        -i <incoming_dir>        --  directory from where pedigrees are analysed"
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

#' ### Create Project Directory
#' Directory used to process a certain pedigree project
#+ create-project-dir-fun
create_project_dir () {
  # check whether project directory already exists
  if [ -d "$PROJDIR" ]
  then
    log_msg 'create_project_dir' " * FOUND project directory $PROJDIR ..."
    usage " *** ERROR: project directory $PROJDIR already exists"
  else
    log_msg 'create_project_dir' " * Create project directory $PROJDIR ..."
    mkdir -p $PROJDIR
  fi
}

#' ### Write Parameter File
#' Parameters used by PopRep are written to a parameter file
#+ write-parameter-file-fun
write_parameter_file () {
  local l_PARAMFILE=${PROJDIR}/param
  log_msg 'write_parameter_file' " * Writing parameters to parameter file: $l_PARAMFILE ..."
  echo "email=${EMAILADDRESS}" > $l_PARAMFILE
  echo "breed=${BREEDNAME}" >> $l_PARAMFILE
  echo "male=${MALECHAR}" >> $l_PARAMFILE
  echo "female=${FEMALECHAR}" >> $l_PARAMFILE
  echo "pedfile=datafile" >> $l_PARAMFILE
  echo "dateformat=${DATEFORMAT}" >> $l_PARAMFILE
  echo "datesep=${DATESEP}" >> $l_PARAMFILE
  echo "get_tar=0" >> $l_PARAMFILE
}

#' ### Move Pedigree
#' Pedigree file is moved to project directory
#+ move-pedigree-file-fun
move_pedigree_file () {
  log_msg 'move_pedigree_file' " * Moving $PEDIGREEFILE to $PROJDIR/datafile ..."
  mv $PEDIGREEFILE $PROJDIR/datafile
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
PROJECTROOT=${HOME}/prp
BREEDNAME='test_breed'
PEDIGREEFILE=''
EMAILADDRESS='fbzws-quagzws@gmail.com'
MALECHAR='M'
FEMALECHAR='F'
DATEFORMAT='YYYY-MM-DD'
DATESEP='-'
INCOMINGDIR='incoming'

while getopts ":b:p:e:m:f:d:s:i:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      BREEDNAME=$OPTARG
      ;;
    p)
      if test -f $OPTARG; then
        PEDIGREEFILE=$OPTARG
      else
        usage "$OPTARG cannot be found as pedigree file ..."
      fi
      ;;
    e)
      EMAILADDRESS=$OPTARG
      ;;
    m)
      MALECHAR=$OPTARG
      ;;
    f)
      FEMALECHAR=$OPTARG
      ;;
    d)
      DATEFORMAT=$OPTARG
      ;;
    s)
      DATESEP=$OPTARG
      ;;
    i)
      INCOMINGDIR=$OPTARG
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
if test "$BREEDNAME" == ""; then
  usage "-b <breed_name> not defined"
fi
if test "$PEDIGREEFILE" == ""; then
  usage "-p <pedigree_data_file> not defined"
fi


#' ## Definition of Project Directory
#' Project is defined based on current date
DATENOW=$(date +"%Y-%m-%d-%H-%M-%S")
PROJDIR=${PROJECTROOT}/${INCOMINGDIR}/${l_DATENOW}

#' ## Prepare Requirements
#' Start to create a directory for the current project
#+ create-project-dir
log_msg "$SCRIPT" ' * Create project directory ...'
create_project_dir


#' ## Write Parameter File
#' Parameters are written to a parameter file
#+ write-parameter-file
log_msg "$SCRIPT" ' * Writing parameter file ...'
write_parameter_file


#' ## Move Pedigree File
#' The pedigree file must be moved to the project directory
#+ move-pedigree-file
log_msg "$SCRIPT" ' * Moving pedigree file ...'
move_pedigree_file


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

