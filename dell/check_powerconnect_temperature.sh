#!/bin/sh
#--------
# Check Powerconnect Stack temperature script for Icinga2
# Require: net-snmp-utils
# v.20160322 by mmarodin
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
        echo "Useage: check_powerconnect_temp.sh -H hostname -C community -w warn -c crit"
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
  [ -z $WARN ] && WARN=45
  [ -z $CRIT ] && CRIT=55

IFS_CURRENT=$IFS
IFS_NEWLINE="
"

IFS=$IFS_NEWLINE
  for STACK in `snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.89.53.15.1.9 | grep -v "No Such Object" | sed 's/.*89.53.15.1.9.\(.*\)/\1/g' | sed 's/^\(.*\) = INTEGER: \(.*\)/\1,\2/g' | sed 's/"//g'` ; do
    UNIT=`echo $STACK | awk 'BEGIN { FS = "," } { print $1 }'`
    TEMPERATURE=`echo $STACK | awk 'BEGIN { FS = "," } { print $2 }'`
    FIRST=$FIRST"Unit#$UNIT:$TEMPERATURE "
    LAST="$LAST \0047unit$UNIT\0137celsius\0047=$TEMPERATURE;$WARN;$CRIT"
      if [ $TEMPERATURE -ge $CRIT ] ; then
	STATUS_CRITICAL=1
      elif [ $TEMPERATURE -ge $WARN ] ; then
	STATUS_WARNING=1
      else
	STATUS_OK=1
      fi
  done
IFS=$IFS_CURRENT

  [ ! "$STACK" ] && echo "No such stack!" && exit 2

echo -n $FIRST"celsius : "

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

echo -e " |$LAST"
exit $EXIT
