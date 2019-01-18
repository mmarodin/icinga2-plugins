#!/bin/sh
#--------
# Check Aruba Networks 5400zl temperature status script for Icinga2
# Tested with K.16.02.x release
# Require: net-snmp-utils, bc
# v.20181015 by mmarodin
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
        echo "Useage: check_5400_temperature.sh -H hostname -C community -V version -w warn -c crit"
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
#  [ -z $WARN ] && WARN="45"
#  [ -z $CRIT ] && CRIT="55"

IFS_CURRENT=$IFS
IFS_NEWLINE="
"

#hpSystemAirCurrentTemp
#.1.3.6.1.4.1.11.2.14.11.1.2.8.1.1.3			(string, 22C)

TEMPERATURE_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.11.2.14.11.1.2.8.1.1.3 |  grep -v "No Such Object" | sed 's/.*\"\(.*\)C\"/\1/g'`)
IFS=$IFS_NEWLINE

  [ ! "$TEMPERATURE_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

TEXT="$TEXT - celsius "$TEMPERATURE_VALUE"C"
TEMPERATURE_ROUND=`echo "scale=0; $TEMPERATURE_VALUE" / 1 | bc`
      
LAST="$LAST celsius=$TEMPERATURE_VALUE;$WARN;$CRIT"

  if [ $TEMPERATURE_ROUND -ge $CRIT ] ; then
    STATUS_CRITICAL=1
  fi

  if [ $TEMPERATURE_ROUND -ge $WARN ] ; then
    STATUS_WARNING=1
  fi

IFS=$IFS_CURRENT

echo -n "Temperature "

  if [ $STATUS_CRITICAL ] ; then
    echo -n "CRITICAL"
    EXIT=2
  elif [ $STATUS_WARNING ] ; then
    echo -n "WARNING"
    EXIT=1
  else
    echo -n "OK"
    EXIT=0
  fi

echo -e "$TEXT |$LAST"
exit $EXIT
