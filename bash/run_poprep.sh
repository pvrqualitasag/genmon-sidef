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
# set -o nounset    # treat unset variables as errors
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
DATENOW=$(date +"%Y-%m-%d-%H-%M-%S")


#' ## Functions
#' The following definitions of general purpose functions are local to this script.
#'
#' ### Usage Message
#' Usage message giving help on how to use the script.
#+ usg-msg-fun, eval=FALSE
usage () {
  local l_MSG=$1
  $ECHO "Usage Error: $l_MSG"
  $ECHO "Usage: $SCRIPT -b <breed_name> -d <pedigree_data_file> -e <email_address> -l <prp_logfile_path> -m <male_char> -f <female_char> -g <group> -y <date_format> -s <data_sep> -u <user> -i <incoming_dir> -p <parameter_file> -r <poprep_proj_path>"
  $ECHO "  where -b <breed_name>          --  name of the breed"
  $ECHO "        -d <pedigree_data_file>  --  pedigree data file of the breed to be analysed"
  $ECHO "        -e <email_address>       --  e-mail address"
  $ECHO "        -f <female_char>         --  character representing female individual in pedigree"
  $ECHO "        -g <group>               --  group to which the user belongs with which we run poprep"
  $ECHO "        -i <incoming_dir>        --  directory from where pedigrees are analysed"
  $ECHO "        -l <prp_logfile_path>    --  path to poprep logfile"
  $ECHO "        -m <male_char>           --  character representing male individual in pedigree"
  $ECHO "        -p <parameter_file>      --  input file with program parameter"
  $ECHO "        -r <poprep_proj_path>    --  poprep project path"
  $ECHO "        -s <date_sep>            --  separator character for dates in pedigree"
  $ECHO "        -u <user>                --  user under which we run poprep"
  $ECHO "        -y <date_format>         --  format for dates in pedigree"
  $ECHO "        -Z                       --  change debug flag to TRUE"
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
  echo "email=${PRPEMAILADDRESS}" > $l_PARAMFILE
  echo "breed=${BREEDNAME}" >> $l_PARAMFILE
  echo "male=${MALECHAR}" >> $l_PARAMFILE
  echo "female=${FEMALECHAR}" >> $l_PARAMFILE
  echo "pedfile=datafile" >> $l_PARAMFILE
  echo "dateformat=${DATEFORMAT}" >> $l_PARAMFILE
  echo "datesep=${DATESEP}" >> $l_PARAMFILE
  echo "get_tar=0" >> $l_PARAMFILE
  echo "prp_wd=${PRPPROJWORKPATH}" >> $l_PARAMFILE
  # copy parameter file to prp work directory
  log_msg 'write_parameter_file' " * Copy $l_PARAMFILE to $PRPPROJPATH ..."
  cp $l_PARAMFILE $PRPPROJPATH
}

#' ### Move Pedigree
#' Pedigree file is moved to project directory
#+ move-pedigree-file-fun
copy_pedigree_file () {
  log_msg 'copy_pedigree_file' " * Copy $PEDIGREEFILE to $PROJDIR/datafile ..."
  cp $PEDIGREEFILE $PROJDIR/datafile
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
BINDROOTCNTRPG=/var/lib/postgresql
BREEDNAME='test_breed'
PEDIGREEFILE=''
PRPEMAILADDRESS='none@neverland.no' #'fbzws-quagzws@gmail.com'
MALECHAR='M'
FEMALECHAR='F'
DATEFORMAT='YYYY-MM-DD'
DATESEP='-'
INCOMINGPATH=${BINDROOTCNTRPG}/incoming
GNMLOGFILE=''
WSUSER=''
WSGROUP=''
PRPPROJPATH=${BINDROOTCNTRPG}/projects
PRPPROJWORKPATH=''
DEBUG='false'
PARAMFILE=''
while getopts ":b:d:e:f:g:i:l:m:p:r:s:u:y:hZ" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      BREEDNAME=$OPTARG
      ;;
    d)
      if test -f $OPTARG; then
        PEDIGREEFILE=$OPTARG
      else
        usage "$OPTARG cannot be found as pedigree file ..."
      fi
      ;;
    e)
      PRPEMAILADDRESS=$OPTARG
      ;;
    f)
      FEMALECHAR=$OPTARG
      ;;
    g)
      WSGROUP=$OPTARG
      ;;
    i)
      INCOMINGPATH=$OPTARG
      ;;
    l)
      GNMLOGFILE=$OPTARG
      ;;
    m)
      MALECHAR=$OPTARG
      ;;
    p)
      PARAMFILE=$OPTARG
      ;;
    r)
      PRPPROJWORKPATH=$OPTARG
      ;;
    s)
      DATESEP=$OPTARG
      ;;
    u)
      WSUSER=$OPTARG
      ;;
    y)
      DATEFORMAT=$OPTARG
      ;;
    Z) 
      DEBUG='true'
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
if test "$BREEDNAME" == ""; then
  usage "-b <breed_name> not defined"
fi
if test "$PEDIGREEFILE" == ""; then
  usage "-d <pedigree_data_file> not defined"
fi


#' ## Path To Incoming Directory
#' The path to the incoming directory
if [ "$INCOMINGPATH" == "" ]
then
  INCOMINGPATH=${BINDROOTCNTRPG}/incoming
fi

#' ## Path to PopRep Project Directory
#' The project path for poprep is specified
#+ default-poprep-wd
if [ "$PRPPROJPATH" == "" ]
then
  PRPPROJPATH=${BINDROOTCNTRPG}/projects
fi

#' ## Overwrite PopRep Working Directory
#' Use the variable PRPPROJWORKPATH which can only changed 
#' by option -r to over-write the poprep working directory
#+ over-write-poprep-wd
TDATE=$(echo $DATENOW | tr -d '-')
if [ "$PRPPROJWORKPATH" != "" ]
then
  PRPPROJPATH=$PRPPROJWORKPATH
else
  PRPPROJPATH=$PRPPROJPATH/${TDATE}_${BREEDNAME}
fi

#' ## Create Project Working directory
#' The working directory for PopRep is created, 
#' if it does not exist yet.
log_msg $SCRIPT " * Check existance of PopRep working directory: $PRPPROJPATH ..."
if [ -d "$PRPPROJPATH" ];then 
  log_msg $SCRIPT "   ==> FOUND PopRep working directory: $PRPPROJPATH ..."
else  
  log_msg $SCRIPT "   ==> Create PopRep working directory: $PRPPROJPATH ..."
  mkdir -p $PRPPROJPATH
fi


#' ## Definition of Project Directory
#' Project is defined based on current date
PROJDIR=${INCOMINGPATH}/${DATENOW}

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
log_msg "$SCRIPT" ' * Copy pedigree file ...'
copy_pedigree_file


#' ## Check Variables
#' The value of APIIS_HOME is checked
log_msg "$SCRIPT" " * APIIS_HOME:     $APIIS_HOME"
log_msg "$SCRIPT" " * INCOMINGPATH:   $INCOMINGPATH"
log_msg "$SCRIPT" " * GNMLOGFILE:     $GNMLOGFILE"
log_msg "$SCRIPT" " * WSUSER:         $WSUSER"
log_msg "$SCRIPT" " * WSGROUP:        $WSGROUP"
log_msg "$SCRIPT" " * PRPPROJPATH:    $PRPPROJPATH"
log_msg "$SCRIPT" " * DEBUG:          $DEBUG"


#' ## Running PopRep
#' PopRep is run with the prepared input
log_msg "$SCRIPT" ' * Running poprep ...'
# $INSTALLDIR/test_process_uploads.sh -i /var/lib/postgresql/incoming -l /home/zws/prp/prplog/popreport.log -u zws -g zws -a /home/popreport/production/apiis -b $BREEDNAME
$APIIS_HOME/bin/process_uploads.sh -i $INCOMINGPATH \
  -l $GNMLOGFILE \
  -u $WSUSER \
  -g $WSGROUP \
  -a $APIIS_HOME \
  -p $PRPPROJPATH \
  -Z $DEBUG



#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

