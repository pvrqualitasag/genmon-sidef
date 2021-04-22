#!/bin/bash
#' ---
#' title: Post Install GenMon
#' date:  2020-08-10 08:41:31
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Seamless running post-installation tasks.
#'
#' ## Description
#' All steps required for running genmon in a singularity container are implemented 
#' in this script. This script must be run by the user that runs the singularity container. 
#'
#' ## Details
#' The tasks run by this script include configuring the postgresql database, 
#' starting the database server, importing the structure of the required database 
#' input and preparing the webserver.
#'
#' ## Example
#' ./post_install_gnm.sh 
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
  $ECHO "Usage: $SCRIPT -p <parameter_config>"
  $ECHO "       where:  -p <parameter_config>        --  (optional) genmon configuration parameter file"
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

#' ### Create PopRep Logfile
#' If it does not exist yet, create the poprep logfile
#+ check-create-gnm-logfile-fun
check_create_gnm_logfile () {
  if [ ! -f "$GNMLOGFILE" ]
  then
    log_msg 'check_create_gnm_logfile' " * Create poprep logfile: $GNMLOGFILE ... "
    touch $GNMLOGFILE
  else
    log_msg 'check_create_gnm_logfile' " * Found poprep logfile: $GNMLOGFILE ... "
  fi
}

#' ### Define Environment Variables
#' Required environment variables are written to rc-files
#+ define-environment-variables-fun
define_environment_variables () {
  log_msg 'define_environment_variables' ' * Define environment variables ...'
  # apiis_GNMADMINHOME in bashrc
  BASHRC=${GNMADMINHOME}/.bashrc
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
  APIISRC=${GNMADMINHOME}/.apiisrc
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
  # change owner of $PGDATADIR
  log_msg "init_pg_server" " ** Change owner of $PGDATADIR to ${PGUSER} ..."
  chown -R ${PGUSER}: $PGDATADIR
  log_msg "init_pg_server" " ** Change owner of $PGLOGDIR to ${PGUSER} ..."
  chown -R ${PGUSER}: $PGLOGDIR
  # initialise a database for $PGUSER
  log_msg "init_pg_server" " ** Init db ..."
  # su -c "$INITDB -D $PGDATADIR -A trust -U $GEOMEADMIN" $PGUSER
  su -c "$INITDB -D $PGDATADIR -A trust -U $PGUSER" $PGUSER
  if [ $? -eq 0 ]
  then
    ok "Initdb successful ..."
  else
    err_exit "Initdb was not possible"
  fi
  # if port is specified, then change it
  if [ "$NEWPGPORT" != '' ]
  then
    log_msg "init_pg_server" " ** Change port in postgresql.conf to $NEWPGPORT ..."
    mv $PGDATADIR/postgresql.conf $PGDATADIR/postgresql.conf.org
    cat $PGDATADIR/postgresql.conf.org | sed -e "s/#port = 5432/port = $NEWPGPORT/" > $PGDATADIR/postgresql.conf
  fi  
}

#' ### Start the PG db-server
#' After initialisation the pg-server must be started
#+ start-pg-server-fun
start_pg_server () {
  log_msg 'start_pg_server' ' ** Starting pg-db-server ...'
  su -c "$PGCTL -D $PGDATADIR -l $PGLOGFILE start" $PGUSER
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
  log_msg 'has_pg_access' " ** Running $PSQL -l ..."
    su -c "$PSQL -l >/dev/null 2>&1"  $PGUSER
    return $?
}

#' ### Check DB User
#' Check whether a db user exists, if not it is created
#+ check-create-db-user-fun
check_create_db_admin () {
  local l_DB_USER=$1
  log_msg 'check_create_db_admin' " ** Postgresql port as PGPORT: $PGPORT ..."
  log_msg 'check_create_db_admin' " ** Check existence of dbuser: $l_DB_USER ..."
  log_msg 'check_create_db_admin' " ** Running command: select usename from pg_user where usename = '$l_DB_USER'"
  local l_NR_REC=$(echo "select usename from pg_user where usename = '$l_DB_USER'" | su -c "$PSQL postgres --tuples-only --quiet --no-align"  $PGUSER | wc -l)
  log_msg 'check_create_db_admin' " ** Number of records for ${l_DB_USER}: $l_NR_REC ..."
  if [ $l_NR_REC -ne 0 ]; then
        ok "PostgreSQL ADMINUSER $l_DB_USER exists"
  else
        log_msg 'check_create_db_admin' " ** Cannot find dbuser: $l_DB_USER ..."
        su -c "$CREATEUSER --superuser $l_DB_USER" $PGUSER
        log_msg 'check_create_db_admin' " ** Created dbuser: $l_DB_USER ..."
        su -c "$PGCTL reload -D $DATA_DIR >/dev/null" $PGUSER
        log_msg 'check_create_db_admin' " ** Reloaded config from $DATA_DIR ..."
        ok "PostgreSQL ADMINUSER $l_DB_USER created"
  fi
}

#' ### Change password for a dbadmin account
#' The geome_admin account requires a specific password which seams to be in the php-code
#+ change-password-db-admin-fun
change_password_db_admin () {
  local l_DB_USER=$1
  local l_DB_PASS=$2
  # check whether account for l_DB_USER exists
  local l_NR_REC=$(echo "select usename from pg_user where usename = '$l_DB_USER'" | su -c "$PSQL postgres --tuples-only --quiet --no-align"  $PGUSER | wc -l)
  log_msg 'change_password_db_admin' " ** Number of records for ${l_DB_USER}: $l_NR_REC ..."
  if [ $l_NR_REC -ne 0 ]
  then
    log_msg 'change_password_db_admin' " ** Change db-password for: $l_DB_USER ..."
    echo "ALTER USER $l_DB_USER PASSWORD '${l_DB_PASS}'"  | su -c "$PSQL postgres" $PGUSER
    ok "Password changed for $l_DB_USER"
  else
    err_exit "CANNOT find dbuser: $l_DB_USER"
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
        su -c "$PGCTL reload -D $DATA_DIR >/dev/null" $PGUSER
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

    DATA_DIR=$(echo "show data_directory" | su -c "$PSQL --tuples-only --quiet --no-align postgres" $PGUSER)
    if [ ! -d $DATA_DIR ]; then
        err_exit "DATA_DIR $DATA_DIR doesn't exist"
    fi
    
    # admin users
    log_msg 'configure_postgresql' " * Check admin user: $APIISADMIN ..."
    check_create_db_admin $APIISADMIN
    log_msg 'configure_postgresql' " * Check admin user: $ADMINUSER ..."
    check_create_db_admin $ADMINUSER
    # log_msg 'configure_postgresql' " * Check admin user: postgres ..."
    # check_create_db_admin postgres
    log_msg 'configure_postgresql' " * Check admin user: $HELIADMIN ..."
    check_create_db_admin $HELIADMIN
    log_msg 'configure_postgresql' " * Check admin user: $GEOMEADMIN ..."
    check_create_db_admin $GEOMEADMIN
    log_msg 'configure_postgresql' " * Change password for admin user: $GEOMEADMIN ..."
    change_password_db_admin $GEOMEADMIN $GEOMEPASS
    
    
    # save old pg_hba.conf and prepend a line:
    log_msg 'configure_postgresql' ' * Check hba conf ...'
    check_hba_conf
}

#' ### Check Status Of DB Server
#' Verification whether the pg DB-server is running or not
#+ pg-db-server-check-fun
pg_server_running () {
  if [ "$NEWPGPORT" != '' ]
  then
    su -c "$PGISREADY -h localhost -p $NEWPGPORT" $PGUSER
  else
    su -c "$PGISREADY -h localhost" $PGUSER
  fi
  # check the return value
  if [ $? -eq 0 ]
  then
    ok "PG db-server is running ..."
  else
    err_exit "PG database server not running"
  fi
}

#' ### Container Check
#' Use env output to check whether this script runs in a container
#+ check-container-fun
check_container () {
  log_msg 'check_container' ' * Checking whether we run in a container ...'
  if [ `env | grep 'SINGULARITY' | wc -l` -eq 0 ]
  then
    err_exit "Script is not running in singularity container"
  else
    ok "Script runs in container ..."
  fi
}

#' ### Import Genmon Database Dump
#' The database dump is imported from an sql file
import_gnm_db_dump () {
  log_msg 'import_gnm_db_dump' " ** Create database GenMon_CH ..."
  su -c "$CREATEDB -O $GEOMEADMIN GenMon_CH" $PGUSER
  log_msg 'import_gnm_db_dump' ' ** Create postgis extension ...'
  su -c "$PSQL -d GenMon_CH -c \"CREATE EXTENSION postgis;\""  $PGUSER
  log_msg 'import_gnm_db_dump' " ** Unzipping the zip file: $GNMSRCDIR/${GNMDUMP}.zip ..."
  unzip $GNMSRCDIR/${GNMDUMP}.zip
  log_msg 'import_gnm_db_dump' " ** Change owner of $GNMDBDUMP to ${WSUSER} ..."
  chown -R ${WSUSER}: $GNMDBDUMP
  log_msg 'import_gnm_db_dump' " ** Moving dump into $GNMDBDUMP ..."
  mv ${GNMDUMP}.sql $GNMDBDUMP
  log_msg 'import_gnm_db_dump' " ** Comment out statement that leads to error in $GNMDBDUMP/${GNMDUMP}.sql"
  sed -i "s/ALTER TABLE public.ofs_ OWNER TO geome_admin;/--ALTER TABLE public.ofs_ OWNER TO geome_admin;/" $GNMDBDUMP/${GNMDUMP}.sql
  log_msg 'import_gnm_db_dump' " ** Import $GNMDBDUMP/${GNMDUMP}.sql ..."
  su -c "$PSQL GenMon_CH < $GNMDBDUMP/${GNMDUMP}.sql" $PGUSER
}

#' ### Change Port in connectDB Script
#' The script connectDatabase.php contains the port of the PG DB. This is 
#' changed to the specified value
change_pg_port () {
  log_msg 'change_pg_port' " ** Change port to $NEWPGPORT in $CONPGDB ..."
  sed -i "s/port=5432/port=$NEWPGPORT/" $CONPGDB
}


#' ## Main Body of Script
#' The main body of the script starts here.
#+ start-msg, eval=FALSE
start_msg

#' ## Define Constants 
#' The following constants are specific for the installation environment. 
#' In case the installation must be made flexible, the constants can be 
#' specified as command-line options.
GNMADMINHOME=/home/gnmzws   # NOTE: inside of the container $HOME is /root
GNMWORKDIR=${GNMADMINHOME}/gnm
PGDATADIR=${GNMWORKDIR}/pgdata
PGLOGDIR=${GNMWORKDIR}/pglog
PGLOGFILE=$PGLOGDIR/`date +"%Y%m%d%H%M%S"`_postgres.log
GNMLOGDIR=${GNMWORKDIR}/gnmlog
GNMLOGFILE=${GNMLOGDIR}/popreport.log
GNMDBDUMP=${GNMWORKDIR}/gnmdbdump
GNMSRCDIR=/var/www/html/genmon-ch
GNMDUMP=empty_GenMon_DB
# the following users are dbusers
ADMINUSER=popreport
APIISADMIN=apiis_admin
HELIADMIN=heli
GEOMEADMIN=geome_admin
GEOMEPASS=geome
# with the following user, the pg-db will be inittialised
PGUSER=postgres
NEWPGPORT='15433'
CONPGDB=$GNMSRCDIR/connectDataBase.php
# webserver user
WSUSER=www-data
# popreport e-mail
PRPEMAILADDRESS='none@neverland.no'

#' ## Getopts for Commandline Argument Parsing
#' If an option should be followed by an argument, it should be followed by a ":".
#' Notice there is no ":" after "h". The leading ":" suppresses error messages from
#' getopts. This is required to get my unrecognized option code to work.
#+ getopts-parsing, eval=FALSE
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


#' ## Check Container Env
#' This script must run from inside a container
#+ check-container
check_container


#' ## Create Logfile for PopRep
#' From the description, it seams that the logfile must be created
#+ check-create-gnm-logfile
log_msg "$SCRIPT" ' * Check PopRep logfile ...'
check_create_gnm_logfile


#' ## Define Environment Variables
#' Environment variables are written to rc-files
#+ define-env-var
log_msg "$SCRIPT" ' * Define environment variables ...'
define_environment_variables


#' ### Determine Version of PG
#' The version of pg is determined
#+ get-pg-version
get_pg_version


#' ### Export Postgresql Port
#' If alternative port is specified, then export it
if [ "$NEWPGPORT" != '' ]
then
  log_msg "$SCRIPT" " ** Postgresql port specified as $NEWPGPORT ..."
  export PGPORT=$NEWPGPORT
  log_msg "$SCRIPT" " ** Postgresql port as PGPORT: $PGPORT ..."
else
  log_msg "$SCRIPT" ' ** Use postgresql default port ...'
fi


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


#' ### Import DB Dump
#' Import the database dump for genmon
#+ import-gnm-dump
log_msg "$SCRIPT" ' * Import db dump...'
import_gnm_db_dump


#' ### Change Port in GenMon
#' The connectDB script contains the pg port
#+ change-pg-port
if [ "$NEWPGPORT" != '' ]
then
  log_msg "$SCRIPT" " * Change pg port in $CONPGDB to $NEWPGPORT ..."
  change_pg_port
fi  


#' ### Change E-Mail Address For PopRep
#' One of the poprep parameters is an e-Mail address. This should be changed 
#' to a default value which causes poprep not to send e-mails.
#+ change-poprep-email
if [ "$PRPEMAILADDRESS" != '' ]
then
  log_msg "$SCRIPT" " * Change poprep e-mail to $PRPEMAILADDRESS ..."
fi


#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

