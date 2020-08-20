#!/bin/bash
#' ---
#' title: Initialise Bash Alias Definition File
#' date:  2020-06-18 09:35:31
#' author: Peter von Rohr
#' ---
#' ## Purpose
#' Provide easy and automated way to initialise an alias definition file.
#'
#' ## Description
#' The alias definition file .bash_aliases is initialised based on a given template.
#'
#' ## Details
#' All-caps strings in curly braces in the template file are treated as placeholders and should be replaced by specified values.
#'
#' ## Example
#' ./init_bash_aliases.sh -a <alias_definition_template>
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
  $ECHO "Usage: $SCRIPT -a <alias_template_file> -t <alias_definition_target>"
  $ECHO "  where -a <alias_template_file>      --  specify a template for the alias definition file (optional)"
  $ECHO "        -t <alias_definition_target>  --  specify target for alias definition file (optional)"
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

#' ### Initialisation of Bash Alias Definition
#' The initialisation can also contain a replacement of placeholders 
#+ init-alias-definition-fun
init_alias_definition () {
  log_msg 'init_alias_definition' " ** INIT alias definition file $ALIASTARGET from template $ALIASDEFTEMPLATE ..."
  cp $ALIASDEFTEMPLATE $ALIASTARGET
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
ALIASDEFTEMPLATE=`$DIRNAME $INSTALLDIR`/template/bash_aliases
ALIASTARGET=${HOME}/.bash_aliases
while getopts ":a:t:ch" FLAG; do
  case $FLAG in
    h)
      usage "Help message for $SCRIPT"
      ;;
    a)
      if test -f $OPTARG; then
        ALIASDEFTEMPLATE=$OPTARG
      else
        usage "$OPTARG isn't a valid alias definition template"
      fi
      ;;
    t)
      ALIASTARGET=$OPTARG
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
if test "$ALIASDEFTEMPLATE" == ""; then
  usage "-a <alias_definition_template> not defined"
fi
if test "$ALIASTARGET" == ""; then
  usage "-t <alias_definition_target_file> not defined"
fi



#' ## Initialise the Alias Definition File
#' If the alias definition target does not exist, initialise it
#+ init-bash-aliases
if [ -f "$ALIASTARGET" ]
then
  log_msg "$SCRIPT" " * FOUND alias definition file: $ALIASTARGET ..."
else
  log_msg "$SCRIPT" " * INIT alias definition  ..."
  init_alias_definition
fi



#' ## End of Script
#+ end-msg, eval=FALSE
end_msg

