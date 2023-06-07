#!/bin/bash
#' ---
#' title: Run GenMon Pedigree Analysis
#' date:  2022-06-28 05:07:07
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless analysis of pedigree data by GenMon
#'
#' ## Description
#' Running a poprep analysis and the computation of the computation of the genmon indices using just one script.
#'
#' ## Details
#' This puts together the analysis of poprep and the post-analysis of the computation of all the indices in one script
#'
#' ## Example
#' ./run_genmon.sh -b tbc2022 -d ../inst/extdata/gnm_test_data/data_sample.csv
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
EVALDIR=$($DIRNAME $INSTALLDIR)
PARDIR=$EVALDIR/par

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
  $ECHO "Usage: $SCRIPT -b <breed_name> -d <path_to_pedigree>"
  $ECHO "  where -b <breed_name>        --  name of the breed to be analysed ..."
  $ECHO "        -d <path_to_pedigree>  --  directory path to pedigree input file ..."
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


#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
PARFILE=$PARDIR/gnm_config.par
BINDROOTCNTRPG=/var/lib/postgresql
NEWPGPORT=5435
PRPPROJPATH=''
BREEDNAME=''
PEDIGREEFILE=''
while getopts ":b:d:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    b)
      BREEDNAME=$OPTARG
      ;;
    d)
      if [ -f "$OPTARG" ];then
        PEDIGREEFILE=$OPTARG
      else
        usage "-d <pedigree_file> CANNOT FIND valid pedigree file: $OPTARG"      
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


#' ## Main Body of Script
#' The main body of the script starts here with a start script message.
#+ start-msg, eval=FALSE
start_msg


#' ## Checks for Command Line Arguments
#' The following statements are used to check whether required arguments
#' have been assigned with a non-empty value
#+ argument-test, eval=FALSE
if test "$BREEDNAME" == ""; then
  usage "-b <breed_name> not defined"
fi
if test "$PEDIGREEFILE" == ""; then
  usage "-d <path_to_pedigree> not defined"
fi

#' ## Defaults for Optional Parameters
#' Use meaningful default for optional parameters
#+ param-defaults
TDATE=$(date +"%Y%m%d%H%M%S")
PRPPROJPATH=$BINDROOTCNTRPG/projects/${TDATE}_${BREEDNAME}


#' ## Export Special PG-Port
#' If defined, export the special PG-PORT
#+ export-pg-port
if [[ $NEWPGPORT != '' ]];then
  log_msg $SCRIPT " * Export PG-Port to: $NEWPGPORT ..."
  export PGPORT=$NEWPGPORT
fi
log_msg $SCRIPT " * Postgres Port: $PGPORT ..."

#' ## Run PopRep Analysis
#' The given pedigree is analysed using PopRep
#+ run-pop-rep
$INSTALLDIR/run_poprep.sh -b $BREEDNAME \
-d $PEDIGREEFILE \
-p $PARFILE \
-r $PRPPROJPATH \
-Z


#' ## Find PopRep Project Name
#' For each analysis, poprep creates an unique project name, this is 
#' required for the post-analysis
#+ get-prp-proj-name
PRPPROJPATH=$(find $PRPPROJPATH -maxdepth 1 -type d -name 'PPP*' -print)
PRPPROJNAME=$(basename $PRPPROJPATH)
log_msg $SCRIPT " * PopRep project name: $PRPPROJNAME ..."


#' ## Run Post-PopRep Analysis
#' Indices for GenMon are computed in this analysis
#+ post-pop-rep
log_msg $SCRIPT " * Running post-prp-analysis for breed: "
$INSTALLDIR/post_prp_analysis.sh -b $BREEDNAME -p $PRPPROJNAME


#' ## End of Script
#' This is the end of the script with an end-of-script message.
#+ end-msg, eval=FALSE
end_msg

