#!/bin/sh
#--------
# Check pCOWeb temperature and humidity status script for Icinga2
# Require: net-snmp-utils, bc
# v.20160608 by mmarodin
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
        echo "Useage: check_pcoweb_temperature.sh -H hostname -V version -C community"
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

# intake_temp		1.3.6.1.4.1.9839.2.1.2.1.0
# intake_temp_1		1.3.6.1.4.1.9839.2.1.2.7.0
# intake_supply		1.3.6.1.4.1.9839.2.1.2.3.0
# blowing_temp		1.3.6.1.4.1.9839.2.1.2.5.0
# cooling_temp		1.3.6.1.4.1.9839.2.1.2.20.0
#
# dehum_set		1.3.6.1.4.1.9839.2.1.3.20.0
# hum_set		1.3.6.1.4.1.9839.2.1.3.21.0
# high_temp		1.3.6.1.4.1.9839.2.1.3.22.0
# min_temp		1.3.6.1.4.1.9839.2.1.3.23.0
# high_hum		1.3.6.1.4.1.9839.2.1.3.24.0
# low_hum		1.3.6.1.4.1.9839.2.1.3.25.0

BASEOID="1.3.6.1.4.1.9839.2.1"

INTAKE_TEMP=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.1.0 | grep -v "No Such Object" | awk '{print $4}'`
INTAKE_TEMP_1=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.7.0 | grep -v "No Such Object" | awk '{print $4}'`
INTAKE_SUPPLY=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.3.0 | grep -v "No Such Object" | awk '{print $4}'`
COOLING_TEMP=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.20 | grep -v "No Such Object" | awk '{print $4}'`

DEHUM_SET=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.3.20.0 | grep -v "No Such Object" | awk '{print $4}'`
HUM_SET=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.3.21.0 | grep -v "No Such Object" | awk '{print $4}'`
HIGH_TEMP=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.3.22.0 | grep -v "No Such Object" | awk '{print $4}'`
MIN_TEMP=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.3.23.0 | grep -v "No Such Object" | awk '{print $4}'`
HIGH_HUM=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.3.24.0 | grep -v "No Such Object" | awk '{print $4}'`
LOW_HUM=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.3.25.0 | grep -v "No Such Object" | awk '{print $4}'`

  [ ! "$INTAKE_TEMP" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$INTAKE_TEMP_1" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$INTAKE_SUPPLY" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$COOLING_TEMP" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  [ ! "$DEHUM_SET" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$HUM_SET" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$HIGH_TEMP" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$MIN_TEMP" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$HIGH_HUM" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$LOW_HUM" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

INTAKE_TEMP=`echo "scale=1; $INTAKE_TEMP / 10" | bc`
INTAKE_TEMP_1=`echo "scale=1; $INTAKE_TEMP_1 / 10" | bc`
INTAKE_SUPPLY=`echo "scale=1; $INTAKE_SUPPLY / 10" | bc`
COOLING_TEMP=`echo "scale=1; $COOLING_TEMP / 10" | bc`

CHECK=`echo "(($INTAKE_TEMP + $INTAKE_TEMP_1) / 2) > ($COOLING_TEMP + 2)" | bc`

  if [ "$CHECK" == "1" ] ; then
    echo -n "CRITICAL"
    EXIT=2
  else
    echo -n "OK"
    EXIT=0
  fi

echo " : Room temp "$INTAKE_TEMP"C - Room temp 1 "$INTAKE_TEMP_1"C - Supply air temp "$INTAKE_SUPPLY"C - Cooling temp "$COOLING_TEMP"C - Dehumidification set $DEHUM_SET% - Humidification set $HUM_SET% - High temp "$HIGH_TEMP"C - Min temp "$MIN_TEMP"C - High humidity $HIGH_HUM% - Low humidity $LOW_HUM% | 'intake_temp'=$INTAKE_TEMP;0;0;0 'intake_temp_1'=$INTAKE_TEMP_1;0;0;0 'intake_supply'=$INTAKE_SUPPLY;0;0;0 'cooling_temp'=$COOLING_TEMP;0;0;0 'dehum_set'=$DEHUM_SET;0;0;0 'hum_set'=$HUM_SET;0;0;0 'high_temp'=$HIGH_TEMP;0;0;0 'min_temp'=$MIN_TEMP;0;0;0 'high_hum'=$HIGH_HUM;0;0;0 'low_hum'=$LOW_HUM;0;0;0"
exit $EXIT
