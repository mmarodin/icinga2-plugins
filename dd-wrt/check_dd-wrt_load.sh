#!/bin/sh
#--------
# Check DD-WRT load script for Icinga2
# Require: net-snmp-utils, bc
# v.20160908 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:w:c:h" optname ; do
    case "$optname" in
      "V")
        VERS=$OPTARG
        ;;
      "H")
        HOST=$OPTARG
        ;;
      "C")
        COMM=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "w")
        WARN=$OPTARG
        ;;
      "h")
        echo "Useage: check_dd-wrt_load.sh -H hostname"
        exit 2
        ;;
      "?")
        echo "Unknown option $OPTARG"
        exit 2
        ;;
      ":")
        echo "No argument value for option $OPTARG"
        exit 2
        ;;
      *)
      # Should not occur
        echo "Unknown error while processing options"
        exit 1
        ;;
    esac
  done

  [ -z $VERS ] && echo "Please specify SNMP version!" && exit 2
  [ -z $HOST ] && echo "Please specify hostname!" && exit 2
  [ -z $COMM ] && echo "Please specify SNMP community!" && exit 2
#  [ -z $WARN ] && WARN=25
#  [ -z $CRIT ] && CRIT=35

LOAD=(`snmpwalk -v$VERS -c $COMM $HOST 1.3.6.1.4.1.2021.10.1.5 | awk '{ print $4}'`)

  [ -z $LOAD ] && exit 2
  [ "${LOAD[*]}" == "Such" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

EXIT=0

echo "SNMP OK - Load ${LOAD[0]}%, ${LOAD[1]}%, ${LOAD[2]}% | 'load1'=${LOAD[0]}%;0;0;0;100 'load5'=${LOAD[1]}%;0;0;0;100 'load15'=${LOAD[2]}%;0;0;0;100"
exit $EXIT