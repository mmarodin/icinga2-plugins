#!/bin/sh
#--------
# Check VISA generator battery voltage script for Icinga2
# Require: net-snmp-utils, bc
# v.20210513 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:m:M:h" optname ; do
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
      "M")
        MAX=$OPTARG
        ;;
      "m")
        MIN=$OPTARG
        ;;
      "h")
        echo "Useage: check_visa_battery.sh -H hostname -C community -V version -m min -M max"
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
  [ -z $MIN ] && MIN="120"
  [ -z $MAX ] && MAX="150"

# vBatteryVoltage
#.1.3.6.1.4.1.28634.17.2.8213			(INTEGER: 139)

VOLTAGE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.28634.17.2.8213 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.28634.17.2.8213.0 = INTEGER: \(.*\)/\1/g'`)

  [ ! "$VOLTAGE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ $VOLTAGE -lt $MAX -a $VOLTAGE -gt $MIN ] && EXIT=0 || EXIT=2

VOLTAGE_VALUE=`echo "scale=1; $VOLTAGE " / 10 | bc`

echo -n "Battery voltage "
  if [ $EXIT -eq 2 ] ; then
    echo -n "CRITICAL"
  else
    echo -n "OK"
  fi
echo -e ": "$VOLTAGE_VALUE"V | voltage=$VOLTAGE_VALUE"
exit $EXIT
