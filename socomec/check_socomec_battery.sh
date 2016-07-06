#!/bin/sh
#--------
# Check Socomec battery status script for Icinga2
# Require: net-snmp-utils, bc
# v.20160524 by mmarodin
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
        echo "Useage: check_socomec_battery.sh -H hostname -V version -C community -w warn -c crit"
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

# upsBatteryStatus              1.3.6.1.4.1.4555.1.1.1.1.2.1
# upsSecondsOnBattery           1.3.6.1.4.1.4555.1.1.1.1.2.2
# upsEstimatedMinutesRemaining  1.3.6.1.4.1.4555.1.1.1.1.2.3
# upsEstimatedChargeRemaining   1.3.6.1.4.1.4555.1.1.1.1.2.4
# upsBatteryVoltage             1.3.6.1.4.1.4555.1.1.1.1.2.5
# upsBatteryTemperature         1.3.6.1.4.1.4555.1.1.1.1.2.6

  [ -z $VERS ] && echo "Please specify SNMP version!" && exit 2
  [ -z $HOST ] && echo "Please specify hostname!" && exit 2
  [ -z $COMM ] && echo "Please specify SNMP community!" && exit 2
  [ -z $WARN ] && WARN=99
  [ -z $CRIT ] && CRIT=98

STATUS=`snmpwalk -v$VERS -c $COMM $HOST 1.3.6.1.4.1.4555.1.1.1.1.2.1.0 | grep -v "No Such Object" | awk '{print $4}'`
CAPACITY=`snmpwalk -v$VERS -c $COMM $HOST 1.3.6.1.4.1.4555.1.1.1.1.2.4.0 | grep -v "No Such Object" | awk '{print $4}'`

  [ ! "$STATUS" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$CAPACITY" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  if [ "$STATUS" != "2" ] ; then
    echo -n "CRITICAL: wrong battery status "
    EXIT=2
  else
    if [ $CAPACITY -le $CRIT ] ; then
      echo -n "CRITICAL"
      EXIT=2
    elif [ $CAPACITY -le $WARN ] ; then
      echo -n "WARNING"
      EXIT=1
    else
      echo -n "OK"
      EXIT=0
    fi
  fi
echo ": Battery capacity $CAPACITY% | 'capacity'=$CAPACITY%;$WARN;$CRIT;0"
exit $EXIT
