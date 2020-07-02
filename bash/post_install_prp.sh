#!/bin/bash
#' ---
#' title: Post Installation Script for PopRep (PRP)
#' date:  2020-06-17 16:50:02
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Running post-installation tasks required for PopRep (prp) automatically.
#'
#' ## Description
#' All tasks required for running prp that cannot be included in the singularity 
#' recipe file are included in this script. The tasks included in this script are 
#' run by the user that is also running the singularity container instance. 
#'
#' ## Details
#' Tasks required to run after building the singularity container for prp.
#'
#' ## Example
#' ./post_install_prp.sh 
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
  $ECHO "Usage: $SCRIPT"
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

#' ### Error and Exit
#' print errors in red on STDERR and exit
#+ err-exit
err_exit () {
    if [[ -t 2 ]] ; then
        printf '\E[31m'; echo "ERROR: $@"; printf '\E[0m'
    else
        echo "$@"
    fi >&2
    exit 1
}

#' ### Print Error On STDERR
#' print errors in red on STDERR
#+ print-error
error () {
    if [[ -t 2 ]] ; then
        printf '\E[31m'; echo "ERROR: $@"; printf '\E[0m'
    else
        echo "$@"
    fi >&2
}

#' ### Print OK
#' Print ok message
#+ print-ok
ok () {
    if [[ -t 2 ]] ; then
        printf '\E[32m'; echo "OK:    $@"; printf '\E[0m'
    else
        echo "$@"
    fi
}

#' ### Print Info Message
#' Print an info message to STDERR
#+ print-info
info () {
    if [[ -t 2 ]] ; then
        printf "\E[34mINFO:  %s\E[0m \n" "$@"
    else
        echo "INFO: $@"
    fi >&2
}

#' ### Check Directory Existence
#' The passed directory is created, if it does not exist. If it exists and is 
#' non-empty the script stops with an error
#+ check-non-empty-dir-fail-create-non-exist-fun
check_non_empty_dir_fail_create_non_exist () {
  local l_check_dir=$1
  if [ -d $l_check_dir ]
  then
    if [ `ls -1 $l_check_dir | wc -l` -gt 0 ]
    then
      err_exit "check_non_empty_dir_fail_create_non_exist: Data directory $l_check_dir exists and is non-empty ==> stop"
    fi
  else
    log_msg "check_non_empty_dir_fail_create_non_exist" " * Create data directory: $l_check_dir"
    mkdir -p $l_check_dir
  fi
  
}


#' ### Check Existence of PRP-Workdir
#' Working directory and substructures are checked. If they do not exist, 
#' an initialisation script is called. 
#+ check-prp-workdir-fun
check_prp_workdir () {
  log_msg 'check_prp_workdir' ' * Check existence of working directory ...'
  if [ ! -d "$PRPWORKDIR" ]
  then
    log_msg 'check_prp_workdir' " ** Create prp-workdir $PRPWORKDIR..."
    $INSTALLDIR/init_prp_workdir.sh
  else
    log_msg 'check_prp_workdir' " ** Found PRP-Workdir $PRPWORKDIR ..."
  fi
}

#' ### Create PopRep Logfile
#' If it does not exist yet, create the poprep logfile
#+ check-create-prp-logfile-fun
check_create_prp_logfile () {
  if [ ! -f "$PRPLOGFILE" ]
  then
    log_msg 'check_create_prp_logfile' " * Create poprep logfile: $PRPLOGFILE ... "
    touch $PRPLOGFILE
  else
    log_msg 'check_create_prp_logfile' " * Found poprep logfile: $PRPLOGFILE ... "
  fi
}

#' ### Define Environment Variables
#' Required environment variables are written to rc-files
#+ define-environment-variables-fun
define_environment_variables () {
  log_msg 'define_environment_variables' ' * Define environment variables ...'
  # apiis_home in bashrc
  BASHRC=${HOME}/.bashrc
  if [ `grep 'APIIS_HOME' $BASHRC | wc -l` -eq 0 ]
  then
    log_msg 'define_environment_variables' " * Add APIIS_HOME to $BASHRC ..."
    (echo;echo '# add apiis_home';echo 'export APIIS_HOME=/home/popreport/production/apiis') >> $BASHRC
    echo 'export PATH=$PATH:$APIIS_HOME/bin' >> $BASHRC
  else
    log_msg 'define_environment_variables' " * FOUND APIIS_HOME in $BASHRC ..."
    grep 'APIIS_HOME' $BASHRC
  fi
  # define project section in .apiisrc
  APIISRC=${HOME}/.apiisrc
  if [ ! -f "$APIISRC" ] || [ `grep '[PROJECTS]' $APIISRC | wc -l` -eq 0 ]
  then
    log_msg 'define_environment_variables' " * Add project section to $APIISRC ..."
    echo "[PROJECTS]" > $APIISRC
    echo 'dummy = $APIIS_HOME/projects' >> $APIISRC
  fi
}

#' ### Obtain Postgres Version
#' Get the version of the installed pg instance
#+ get-pg-version-fun
get_pg_version () {
    info "collecting PG_version information"
    # we get here only after we have tested that there is only one
    # version of postgresql installed.
    # need PG_ALLVERSION  like 9.4 or 10
    # need PG_SUBVERSION  like 4
    # need PG_VERSION     like 9
    # need PG_PACKET      like postgresql_11
    PG_PACKET=$(dpkg -l postgresql*    | egrep 'ii ' |egrep "SQL database, version" |awk '{print $2}')
    PG_SUBVERSION=''
    if [ -n "$PG_PACKET"  ]; then
       if [[ $PG_PACKET = *9.* ]]; then
# subv wird packet bei 10 11 etc
          PG_SUBVERSION=$(dpkg -l postgresql*| egrep 'ii ' |egrep "SQL database, version" |awk '{print $2}'|sed -e 's/postgresql-9.//')
       else
          PG_SUBVERSION=' '
          echo no subversion
       fi
    fi

    PG_ALLVERSION=$(dpkg -l postgresql*| egrep 'ii ' |egrep "SQL database, version" |awk '{print $2}'|sed -e 's/postgresql-//')
    PG_VERSION=$(echo $PG_ALLVERSION |  cut -d. -f1)
    echo packet_____:$PG_PACKET
    echo version____:$PG_VERSION
    echo subversion_:$PG_SUBVERSION
    echo allversion_:$PG_ALLVERSION
}

#' ### Initialisation of the PG db-server
#' All initialisation steps are done in this function
#+ init-pg-server-fun
init_pg_server () {
  # check that data directory does not exist
  check_non_empty_dir_fail_create_non_exist $PGDATADIR
  # initialise a database for $OSUSER
  log_msg "init_pg_server" " * Init db ..."
  $INITDB -D $PGDATADIR -A trust -U $OSUSER
  if [ $? -eq 0 ]
  then
    ok "Initdb successful ..."
  else
    err_exit "Initdb was not possible"
  fi
}

#' ### Start the PG db-server
#' After initialisation the pg-server must be started
#+ start-pg-server-fun
start_pg_server () {
  log_msg 'start_pg_server' ' * Starting pg-db-server ...'
  $PGCTL -D $PGDATADIR -l $PGLOGFILE start
  if [ $? -eq 0 ]
  then
    ok "PG server started successfully ..."
  else
    err_exit "Cannot start pg server ..."
  fi
}

#' ### Access To DB
#' Check wheter we can access the database
#+ has-pg-access-fun
has_pg_access () {
    $PSQL -l >/dev/null 2>&1
    return $?
}

#' ### Check DB User
#' Check whether a db user exists, if not it is created
#+ check-create-db-user-fun
check_create_db_admin () {
  local l_DB_USER=$1
  log_msg 'check_create_db_admin' " ** Check existence of dbuser: $l_DB_USER ..."
  echo "select usename from pg_user where usename = '$l_DB_USER'" | $PSQL postgres --tuples-only --quiet --no-align | grep -q $l_DB_USER >/dev/null
  if [ $? -eq 0 ]; then
        ok "PostgreSQL ADMINUSER $l_DB_USER exists"
  else
        $CREATEUSER --superuser $l_DB_USER
        $PGCTL reload -D $DATA_DIR >/dev/null
        ok "PostgreSQL ADMINUSER $l_DB_USER created"
  fi
}

#' ### Check HBA Config
#' Check configuration in pag_hba.conf
#+ check-hba-conf-fun
check_hba_conf () {
    # save old pg_hba.conf and prepend a line:
    grep -q "^host  *all  *all .*trust$" $ETC_DIR/pg_hba.conf >/dev/null
    if [ $? -eq 0 ]; then
        ok "$ETC_DIR/pg_hba.conf already configured"
    else
        NOW=$(date +"%Y-%m-%d_%H:%M:%S")
        mv $ETC_DIR/pg_hba.conf $ETC_DIR/pg_hba.conf-saved-$NOW
        echo "# next line added by TheSNPpit installation routine ($NOW)" >$ETC_DIR/pg_hba.conf
        echo "# only these two lines are required, that standard configuration"
        echo "# as usually (2019) can be found the end can stay as is"
        # IPV4:
        echo "host  all   all   127.0.0.1/32   trust" >>$ETC_DIR/pg_hba.conf
        # IPV6:
        echo "host  all   all   ::1/128        trust" >>$ETC_DIR/pg_hba.conf
        cat $ETC_DIR/pg_hba.conf-saved-$NOW >>$ETC_DIR/pg_hba.conf
        info "Note: $ETC_DIR/pg_hba.conf saved to $ETC_DIR/pg_hba.conf-saved-$NOW and adapted"
        $PGCTL reload -D $DATA_DIR >/dev/null
    fi
}

#' ### Configure PG Database
#' Configuration of pg database
#+ config-pg-fun
configure_postgresql () {
    log_msg 'configure_postgresql' ' ** Start pg-db config ...'
    # create snpadmin with superuser privilege
    # info "Running configure_postgresql ..."
    # as of version 10 no subversion: postgresql-10: use the 10
    # VERSION is now version.subversion as used in ETC_DIR
    ETC_DIR="$PGDATADIR"
    if [ ! -d $ETC_DIR ]; then
        err_exit "ETC_DIR $ETC_DIR doesn't exist"
    fi
    # setting the port
    
    log_msg 'configure_postgresql' ' ** Checking pg-access ...'
    has_pg_access
    if [ $? -ne 0 ]; then
        error "You have no right to access postgresql ..."
    fi

    DATA_DIR=$(echo "show data_directory" | $PSQL --tuples-only --quiet --no-align postgres)
    if [ ! -d $DATA_DIR ]; then
        err_exit "DATA_DIR $DATA_DIR doesn't exist"
    fi
    
    # admin users
    log_msg 'configure_postgresql' " * Check admin user: $APIISADMIN ..."
    check_create_db_admin $APIISADMIN
    log_msg 'configure_postgresql' " * Check admin user: $ADMINUSER ..."
    check_create_db_admin $ADMINUSER
    log_msg 'configure_postgresql' " * Check admin user: postgres ..."
    check_create_db_admin postgres
    log_msg 'configure_postgresql' " * Check admin user: $HELIADMIN ..."
    check_create_db_admin $HELIADMIN
    
    # save old pg_hba.conf and prepend a line:
    log_msg 'configure_postgresql' ' * Check hba conf ...'
    check_hba_conf
}

#' ### Check Status Of DB Server
#' Verification whether the pg DB-server is running or not
#+ pg-db-server-check-fun
pg_server_running () {
  if [ "$PG_PORT" != '' ]
  then
    $PGISREADY -h localhost -p $PG_PORT
  else
    $PGISREADY -h localhost 
  fi
  # check the return value
  if [ $? -eq 0 ]
  then
    ok "PG db-server is running ..."
  else
    err_exit "PG database server not running"
  fi
}




#' ## Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ## Define Constants 
#' The following constants are specific for the installation environment. 
#' In case the installation must be made flexible, the constants can be 
#' specified as command-line options.
PRPWORKDIR=${HOME}/prp
PGDATADIR=${PRPWORKDIR}/pgdata
PGLOGDIR=${PRPWORKDIR}/pglog
PGLOGFILE=$PGLOGDIR/`date +"%Y%m%d%H%M%S"`_postgres.log
PRPLOGDIR=${PRPWORKDIR}/prplog
PRPLOGFILE=${PRPLOGDIR}/popreport.log
ADMINUSER=popreport
APIISADMIN=apiis_admin
HELIADMIN=heli
OSUSER=`whoami`
PG_PORT=''

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
# a_example=""
# b_example=""
# c_example=""
# while getopts ":a:b:ch" FLAG; do
#   case $FLAG in
#     h)
#       usage "Help message for $SCRIPT"
#       ;;
#     a)
#       a_example=$OPTARG
# OR for files
#      if test -f $OPTARG; then
#        a_example=$OPTARG
#      else
#        usage "$OPTARG isn't a regular file"
#      fi
# OR for directories
#      if test -d $OPTARG; then
#        a_example=$OPTARG
#      else
#        usage "$OPTARG isn't a directory"
#      fi
#       ;;
#     b)
#       b_example=$OPTARG
#       ;;
#     c)
#       c_example="c_example_value"
#       ;;
#     :)
#       usage "-$OPTARG requires an argument"
#       ;;
#     ?)
#       usage "Invalid command line argument (-$OPTARG) found"
#       ;;
#   esac
# done
# 
# shift $((OPTIND-1))  #This tells getopts to move on to the next argument.


#' ## Check Existence of Workdirectory 
#' Directory infrastructure is checked
#+ check-exist-workdir
log_msg "$SCRIPT" ' * Check PopRep work directory ...'
check_prp_workdir


#' ## Create Logfile for PopRep
#' From the description, it seams that the logfile must be created
#+ check-create-prp-logfile
log_msg "$SCRIPT" ' * Check PopRep logfile ...'
check_create_prp_logfile


#' ## Define Environment Variables
#' Environment variables are written to rc-files
#+ define-env-var
log_msg "$SCRIPT" ' * Define environment variables ...'
define_environment_variables


#' ### Determine Version of PG
#' The version of pg is determined
#+ get-pg-version
get_pg_version

#' ### Postgresql Programs
#' Explicit definitions of pg programs depending on pg version
#+ pg-prog-def
INITDB="/usr/lib/postgresql/$PG_ALLVERSION/bin/initdb"
PSQL="/usr/lib/postgresql/$PG_ALLVERSION/bin/psql"
CREATEDB="/usr/lib/postgresql/$PG_ALLVERSION/bin/createdb"
CREATEUSER="/usr/lib/postgresql/$PG_ALLVERSION/bin/createuser"
PGCTL="/usr/lib/postgresql/$PG_ALLVERSION/bin/pg_ctl"
PGISREADY="/usr/lib/postgresql/$PG_ALLVERSION/bin/pg_isready"
ETCPGCONF="/etc/postgresql/$PG_ALLVERSION/main/postgresql.conf"
PGSTART="$INSTALLDIR/pg_start.sh"
PGSTOP="$INSTALLDIR/pg_stop.sh"

#' ### Initialisation of PG-DB
#' The configuration steps of the pg database that require to be run as 
#' user zws with its home directory available are done from here on.
#+ init-pg-server-call
log_msg "$SCRIPT" "Initialise the postgres db instance ..."
init_pg_server


#' ### Start the PG-db-server
#' After initialisation the db-server must be started
#+ start-pg-db-server
log_msg "$SCRIPT" ' * Starting pg server ...'
start_pg_server


#' ### Configure PG
#' Configurationf of pg database
#+ configure-pg
log_msg "$SCRIPT" ' * Configure pg db ...'
configure_postgresql


#' check whether the pg db-server is running
# log_msg "$SCRIPT" ' * Check whether pg server is running ...'
# pg_server_running

#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

