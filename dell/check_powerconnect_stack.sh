#!/bin/sh
#--------
# Check Powerconnect Stack status script for Icinga2
# Require: net-snmp-utils
# v.20160617 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:h" optname ; do
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
      "h")
        echo "Useage: check_powerconnect_stack.sh -H hostname -C community"
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

STATUS=`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.89.107.3.0 | grep -v "No Such Object" | awk '{print $4}'`

  [ ! "$STATUS" ]  && echo "Execution problem, probably hostname did not respond!" && exit 2


  if [ $STATUS -eq 2 ] ; then
    echo "OK - stack alive"
    EXIT=0
  else
    echo "CRITICAL - stack dead"
    EXIT=2
  fi

exit $EXIT
