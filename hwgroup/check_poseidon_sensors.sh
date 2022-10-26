#!/bin/sh
#--------
# Check HWGroup Poseidon sensors/temperature status script for Icinga2
# Require: net-snmp-utils, bc
# v.20220607 by mmarodin
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
        echo "Useage: check_poseidon_sensors.sh -H hostname -C community -V version"
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

IFS_CURRENT=$IFS
IFS_NEWLINE="
"
#SNMPv2-SMI::enterprises.21796.3.3.3.1.2.1 = STRING: "Container Frozen"		Sensor name (R/W string)
#SNMPv2-SMI::enterprises.21796.3.3.3.1.2.2 = STRING: "Cella Frigo"
#SNMPv2-SMI::enterprises.21796.3.3.3.1.2.3 = STRING: "Cella Frozen"
#SNMPv2-SMI::enterprises.21796.3.3.3.1.4.1 = INTEGER: 2				Sensor state (integer, 0=Invalid, 1=Normal, 2=AlarmState, 3=Alarm)
#SNMPv2-SMI::enterprises.21796.3.3.3.1.4.2 = INTEGER: 2
#SNMPv2-SMI::enterprises.21796.3.3.3.1.4.3 = INTEGER: 2
#SNMPv2-SMI::enterprises.21796.3.3.3.1.5.1 = STRING: "-22.3 C"			Sensor current value, units included (string)
#SNMPv2-SMI::enterprises.21796.3.3.3.1.5.2 = STRING: "13.1 C"
#SNMPv2-SMI::enterprises.21796.3.3.3.1.5.3 = STRING: "11.1 C"
#SNMPv2-SMI::enterprises.21796.3.3.3.1.6.1 = INTEGER: -223			Sensor current value *10 (integer)
#SNMPv2-SMI::enterprises.21796.3.3.3.1.6.2 = INTEGER: 131
#SNMPv2-SMI::enterprises.21796.3.3.3.1.6.3 = INTEGER: 111
#SNMPv2-SMI::enterprises.21796.3.3.3.1.7.1 = INTEGER: -223			?
#SNMPv2-SMI::enterprises.21796.3.3.3.1.7.2 = INTEGER: 131
#SNMPv2-SMI::enterprises.21796.3.3.3.1.7.3 = INTEGER: 111
#SNMPv2-SMI::enterprises.21796.3.3.3.1.8.1 = INTEGER: 9729			Sensor unique ID (integer)
#SNMPv2-SMI::enterprises.21796.3.3.3.1.8.2 = INTEGER: 33281
#SNMPv2-SMI::enterprises.21796.3.3.3.1.8.3 = INTEGER: 62465
#SNMPv2-SMI::enterprises.21796.3.3.3.1.9.1 = INTEGER: 0
#SNMPv2-SMI::enterprises.21796.3.3.3.1.9.2 = INTEGER: 0
#SNMPv2-SMI::enterprises.21796.3.3.3.1.9.3 = INTEGER: 0
#SNMPv2-SMI::enterprises.21796.3.3.3.1.10.1 = STRING: "C"			Sensor units (integer, 0=°C, 1=°F, 2=°K, 3=%, 4=V, 5=mA, 6=unknown, 7=pulse, 8=switch)
#SNMPv2-SMI::enterprises.21796.3.3.3.1.10.2 = STRING: "C"
#SNMPv2-SMI::enterprises.21796.3.3.3.1.10.3 = STRING: "C"
#SNMPv2-SMI::enterprises.21796.3.3.3.1.11.1 = INTEGER: 3			?
#SNMPv2-SMI::enterprises.21796.3.3.3.1.11.2 = INTEGER: 1
#SNMPv2-SMI::enterprises.21796.3.3.3.1.11.3 = INTEGER: 2

BASEOID="1.3.6.1.4.1.21796.3.3.3.1"

IFS=$IFS_NEWLINE
#SENSORS_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.5 |  grep -v "No Such Object" | sed 's/.*\"\(.*\) C\"/\1/g'`)
SENSORS_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.5 |  grep -v "No Such Object" | sed 's/.*\"\(.*\) .*\"/\1/g'`)
SENSORS_NAME=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2 |  grep -v "No Such Object" | sed 's/.*\"\(.*\)\"/\1/g'`)
SENSORS_STATUS=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.4 |  grep -v "No Such Object" | sed 's/.*INTEGER: \(.*\)/\1/g'`)

  [ ! "$SENSORS_NAME" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$SENSORS_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$SENSORS_STATUS" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  for INDEX in "${!SENSORS_VALUE[@]}" ; do
    if [[ "${SENSORS_NAME[$INDEX]}" != *"Sensor "* ]] ; then
      TEXT="$TEXT - ${SENSORS_NAME[$INDEX]} ${SENSORS_VALUE[$INDEX]}"
      SENSOR_ROUND=`echo "scale=0; ${SENSORS_VALUE[$INDEX]}" / 1 | bc`
      LAST="$LAST ${SENSORS_NAME[$INDEX]// /_}=${SENSORS_VALUE[$INDEX]}"
        if [[ ${SENSORS_STATUS[$INDEX]} -ne 1  ]] ; then
	  TEXT_CRIT="$TEXT_CRIT - ${SENSORS_NAME[$INDEX]} ${SENSORS_VALUE[$INDEX]}"
	  STATUS_CRITICAL=1
	  continue
        fi
    fi
  done

IFS=$IFS_CURRENT

echo -n "Sensors "

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

  [ "$TEXT_CRIT" != "" ] && echo -n "$TEXT_CRIT" || echo -n "$TEXT"

echo -e " |$LAST"
exit $EXIT
