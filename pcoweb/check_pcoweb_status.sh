#!/bin/sh
#--------
# Check pCOWeb sensor status script for Icinga2
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
        echo "Useage: check_pcoweb_status.sh -H hostname -V version -C community"
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

# 14 Air flow switch
# 15 Emergency chiller
# 18 Maintainance alarm
# 19 Phase sequency alarm

# 20 Wrong phases sequence
# 22 Smoke and fire sensors
# 23 Flooding
# 24 Loss air
# 25 High pressure cirtuit 1
# 26 High pressure cirtuit 2
# 27 Low pressure circuit 1
# 28 Low pressure circuit 2

# 29 High pressure from pressure switch
# 30 Low pressure from pressure switch

# 31 Resistor overheating
# 32 Air filter
# 33 Humidifier high current
# 34 Humidifier no water
# 33 Humidifier low current
# 36 EEPROM failure
# 37 Loss water flow
# 38 Temperature sensor
# 39 Humidity sensor
# 40 Supply air temperature failure
# 41 Cold water temperature
# 42 Hot water temperature sensor failure
# 43 Outdoor air temperature sensor failure
# 45 High room temperature
# 46 Low room temperature
# 47 High room humidity
# 48 Low room humidity
# 49 High water temperature

# 50 Sum of all alarms

# 51 General alarm
# 52 Scheduled maintenance

BASEOID="1.3.6.1.4.1.9839.2.1.1"

OID_NR=('20' '22' '23' '24' '25' '26' '27' '28' '31' '32' '33' '34' '33' '36' '37' '38' '39' '40' '41' '42' '43' '45' '46' '47' '48' '49' '51' '52')
OID_DESCR=('Wrong phases sequence' 'Smoke and fire sensors' 'Flooding' 'Loss air' 'High pressure cirtuit 1' 'High pressure cirtuit 2' 'Low pressure circuit 1' 'Low pressure circuit 2' 'Resistor overheating' 'Air filter' 'Humidifier high current' 'Humidifier no water' 'Humidifier low current' 'EEPROM failure' 'Loss water flow' 'Temperature sensor' 'Humidity sensor' 'Supply air temperature failure' 'Cold water temperature' 'Hot water temperature sensor failure' 'Outdoor air temperature sensor failure' 'High room temperature' 'Low room temperature' 'High room humidity' 'Low room humidity' 'High water temperature' 'General alarm' 'Scheduled maintenance')

COUNT=0
MULTIPLE=0

  for OID in "${OID_NR[@]}" ; do
    VALUE=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.$OID.0 | grep -v "No Such Object" | awk '{print $4}'`
      if [ "$VALUE" != "0" ] ; then
	  [ $MULTIPLE -eq 1 ] && OUTPUT="$OUTPUT, "
	OUTPUT="$OUTPUT${OID_DESCR[$COUNT]}"
	MULTIPLE=1
      fi
    COUNT=`echo "$COUNT + 1" | bc`
  done

  if [ $MULTIPLE -eq 1 ] ; then
    echo "CRITICAL - Sensors with problems: $OUTPUT"
    EXIT=2
  else
    echo "OK - All sensors are good"
    EXIT=0
  fi

exit $EXIT
