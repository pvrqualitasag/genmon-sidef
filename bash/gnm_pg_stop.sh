#!/bin/bash
#' ---
#' title: Stop Postgresql Database Server for GenMon
#' date:  2020-08-10 11:00:31
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless stopping procedure for postgresql database server.
#'
#' ## Description
#' Stopping an instance of the postgresql database for GenMon.
#'
#' ## Details
#' The stopping procedure should remove any trailing items after stopping the database-server.
#'
#' ## Example
#' ./gnm_pg_stop.sh -d <data_dir> -p <param_config_file
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
  $ECHO "Usage: $SCRIPT -p <param_config_file>"
  $ECHO "  where -p <param_config_file>  --  parameter configuration file"
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

#' ### Obtain Postgres Version
#' Get the version of the installed pg instance
#+ get-pg-version-fun
get_pg_version () {
    log_msg 'get_pg_version' " * Determine PG_version information ..."
    PG_ALLVERSION=''
    # check whether version file is available
    if [ -f "$PGVERSIONFILE" ]
    then
      PG_ALLVERSION=$(cat $PGVERSIONFILE)
      log_msg 'get_pg_version' " * Determine pg-version from version file: $PG_ALLVERSION ..."
    else
      # no version file => use db  
      # we get here only after we have tested that there is only one
      # version of postgresql installed.
      # need PG_ALLVERSION  like 9.4 or 10
      # need PG_SUBVERSION  like 4
      # need PG_VERSION     like 9
      # need PG_PACKET      like postgresql_11
      PG_PACKET=$(dpkg -l postgresql*    | egrep 'ii ' |egrep "$PGVERPATTERN" |awk '{print $2}')
      PG_SUBVERSION=''
      if [ -n "$PG_PACKET"  ]; then
         if [[ $PG_PACKET = *9.* ]]; then
           # subv wird packet bei 10 11 etc
           PG_SUBVERSION=$(dpkg -l postgresql*| egrep 'ii ' |egrep "$PGVERPATTERN" |awk '{print $2}'|sed -e 's/postgresql-9.//')
         else
           PG_SUBVERSION=' '
           echo no subversion
        fi
      fi
      PG_ALLVERSION=$(dpkg -l postgresql*| egrep 'ii ' |egrep "$PGVERPATTERN" |awk '{print $2}'|sed -e 's/postgresql-//')  
    fi 
    # check whether version could be determined
    if [ "$PG_ALLVERSION" == '' ]
    then
      usage " *** ERROR: Cannot determin the PG-Version ..."
    fi
    PG_VERSION=$(echo $PG_ALLVERSION |  cut -d. -f1)
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
GNMADMINHOME=/home/gnmzws
PGDATADIR=${GNMADMINHOME}/gnm/pgdata
PGVERSIONFILE=$PGDATADIR/PG_VERSION
PGVERPATTERN='Relational Database'
NEWPGPORT='15433'
PGUSER=postgres
PARAMFILE=''
while getopts ":p:h" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    p)
      PARAMFILE=$OPTARG
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


#' ### Determine Version of PG
#' The version of pg is determined
#+ get-pg-version
get_pg_version


#' ### Define Variable
#' Commands used with pg are defined with variables
#+ pg-var-def
PGBIN="/usr/lib/postgresql/$PG_ALLVERSION/bin"
PGCTL=$PGBIN/pg_ctl
PGISREADY=$PGBIN/pg_isready
#' ### Export Postgresql Port
#' If alternative port is specified, then export it
if [ "$NEWPGPORT" != '' ]
then
  log_msg "$SCRIPT" " ** Postgresql port specified as $NEWPGPORT ==> exported as PGPORT"
  export PGPORT=$NEWPGPORT
else
  log_msg "$SCRIPT" ' ** Use postgresql default port ...'
fi

#' ## Stopping the pg-server
#' The pg-server is stopped with the pg_ctl command
#+ pg-server-stop
if [ `su -c "$PGISREADY" $PGUSER | grep 'accepting connections' | wc -l` -eq 1 ]
then
  log_msg "$SCRIPT" ' * Stop running Postgresql database ...'
  su -c "$PGCTL -D $PGDATADIR stop" $PGUSER
else
  log_msg "$SCRIPT" ' * Cannot find running Postgresql database  ...'
fi

#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

