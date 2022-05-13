#!/bin/sh
#--------
# Check APC PDU temperature and humidity status script for Icinga2
# Require: net-snmp-utils, bc
# v.20210518 by mmarodin
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
        echo "Useage: check_apc_pdu_temperature.sh -H hostname -C community -V version -w warn -c crit"
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
  [ -z $WARN ] && WARN="30"
  [ -z $CRIT ] && CRIT="40"

# rPDU2SensorTempHumidityStatusTempC
#.1.3.6.1.4.1.318.1.1.26.10.2.2.1.8.1		(INTEGER: 219)
# rPDU2SensorTempHumidityStatusRelativeHumidity
#.1.3.6.1.4.1.318.1.1.26.10.2.2.1.10.1          (INTEGER: 48)

TEMP=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.318.1.1.26.10.2.2.1.8.1 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.318.1.1.26.10.2.2.1.8.1 = INTEGER: \(.*\)/\1/g'`)
HUMIDITY=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.318.1.1.26.10.2.2.1.10.1 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.318.1.1.26.10.2.2.1.10.1 = INTEGER: \(.*\)/\1/g'`)

  [ ! "$TEMP" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$HUMIDITY" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ $TEMP -eq -1 ] && echo "No sensor found!" && exit 1

TEMP_VALUE=`echo "scale=1; $TEMP " / 10 | bc`
TEMP_ROUND=`echo "scale=0; $TEMP " / 10 | bc`

  if [ $TEMP_ROUND -gt $CRIT ] ; then
    TEXT="CRITICAL"
    EXIT=2
  elif [ $TEMP_ROUND -gt $WARN ] ; then
    TEXT="WARNING"
    EXIT=1
  else
    TEXT="OK"
    EXIT=0
  fi

echo "PDU environment $TEXT: temp "$TEMP_VALUE"C, hum "$HUMIDITY"% RH | temperature=$TEMP_VALUE humidity=$HUMIDITY"
exit $EXIT
