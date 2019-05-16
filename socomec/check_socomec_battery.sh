#!/bin/sh
#--------
# Check Socomec Netvision/RTvision battery status script for Icinga2
# Require: net-snmp-utils, bc
# v.20190516 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:w:c:N:m:h" optname ; do
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
      "N")
        NEW=$OPTARG
        ;;
      "m")
        MODE=$OPTARG
        ;;
      "h")
        echo "Useage: check_socomec_battery.sh -H hostname -V version -C community -w warn -c crit [-N] -m [net|rt]"
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

#NETVISION
# upsBatteryStatus              1.3.6.1.4.1.4555.1.1.1.1.2.1
# upsSecondsOnBattery           1.3.6.1.4.1.4555.1.1.1.1.2.2
# upsEstimatedMinutesRemaining  1.3.6.1.4.1.4555.1.1.1.1.2.3
# upsEstimatedChargeRemaining   1.3.6.1.4.1.4555.1.1.1.1.2.4
# upsBatteryVoltage             1.3.6.1.4.1.4555.1.1.1.1.2.5
# upsBatteryTemperature         1.3.6.1.4.1.4555.1.1.1.1.2.6

#RTVISION
#dupsRatingBatteryVoltage       1.3.6.1.4.1.2254.2.4.1.12
#dupsConfigExternalBatteryPack  1.3.6.1.4.1.2254.2.4.3.8
#dupsBattery                    1.3.6.1.4.1.2254.2.4.7
#dupsBatteryCondiction          1.3.6.1.4.1.2254.2.4.7.1
#dupsBatteryStatus              1.3.6.1.4.1.2254.2.4.7.2
#dupsBatteryCharge              1.3.6.1.4.1.2254.2.4.7.3
#dupsSecondsOnBattery           1.3.6.1.4.1.2254.2.4.7.4
#dupsBatteryEstimatedTime       1.3.6.1.4.1.2254.2.4.7.5
#dupsBatteryVoltage             1.3.6.1.4.1.2254.2.4.7.6
#dupsBatteryCurrent             1.3.6.1.4.1.2254.2.4.7.7
#dupsBatteryCapacity            1.3.6.1.4.1.2254.2.4.7.8
#dupsAlarmBatteryLow            1.3.6.1.4.1.2254.2.4.9.3
#dupsAlarmBatteryGroundFault    1.3.6.1.4.1.2254.2.4.9.8
#dupsAlarmBatteryTestFail       1.3.6.1.4.1.2254.2.4.9.10
#dupsLowBattery                 1.3.6.1.4.1.2254.2.4.20.0.5
#dupsReturnFromLowBattery       1.3.6.1.4.1.2254.2.4.20.0.6
#dupsBatteryGroundFault         1.3.6.1.4.1.2254.2.4.20.0.15
#dupsNoLongerBatteryFault       1.3.6.1.4.1.2254.2.4.20.0.16
#dupsBatteryTestFail            1.3.6.1.4.1.2254.2.4.20.0.18

  [ -z $VERS ] && echo "Please specify SNMP version!" && exit 2
  [ -z $HOST ] && echo "Please specify hostname!" && exit 2
  [ -z $COMM ] && echo "Please specify SNMP community!" && exit 2
  [ -z $WARN ] && WARN=99
  [ -z $CRIT ] && CRIT=98
  [ -z $MODE ] && MODE="net"

  if [ "$MODE" == "rt" ] ; then
    S_OID="1.3.6.1.4.1.2254.2.4.7.2"
    C_OID="1.3.6.1.4.1.2254.2.4.7.8"
    CHECK=0
  else
    S_OID="1.3.6.1.4.1.4555.1.1.1.1.2.1.0"
    C_OID="1.3.6.1.4.1.4555.1.1.1.1.2.4.0"
      [ "$NEW" ] && CHECK=5 || CHECK=2
  fi

STATUS=`snmpwalk -v$VERS -c $COMM $HOST $S_OID | grep -v "No Such Object" | awk '{print $4}'`
CAPACITY=`snmpwalk -v$VERS -c $COMM $HOST $C_OID | grep -v "No Such Object" | awk '{print $4}'`

  [ ! "$STATUS" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$CAPACITY" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  if [ "$STATUS" != "$CHECK" ] ; then
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
