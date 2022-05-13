#!/bin/sh
#--------
# Check HWGroup STE2 flood status script for Icinga2
# Require: net-snmp-utils, bc
# v.20180504 by mmarodin
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
      "c")
        CRIT=$OPTARG
        ;;
      "w")
        WARN=$OPTARG
        ;;
      "h")
        echo "Useage: check_ste2_flood.sh -H hostname -C community -V version"
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

#.1.3.6.1.4.1.21796.4.9.3.1.1.n Sensor Index         (integer,  NUM  (1..x))
#.1.3.6.1.4.1.21796.4.9.3.1.2.n Sensor Name          (string,   SIZE (0..16))
#.1.3.6.1.4.1.21796.4.9.3.1.3.n Sensor State         (integer,  0=Invalid, 1=Normal, 2=OutOfRangeLo, 3=OutOfRangeHi, 4=AlarmLo, 5=AlarmHi)
#.1.3.6.1.4.1.21796.4.9.3.1.4.n Sensor String Value  (string,   SIZE (0..10))
#.1.3.6.1.4.1.21796.4.9.3.1.5.n Sensor Value         (integer,  current value *10)
#.1.3.6.1.4.1.21796.4.9.3.1.6.n Sensor SN            (string,   SIZE (0..16))
#.1.3.6.1.4.1.21796.4.9.3.1.7.n Sensor Unit          (integer,  0=unknown, 1=°C, 2=°F, 3=°K, 4=%)
#.1.3.6.1.4.1.21796.4.9.3.1.8.n Sensor ID            (integer,  NUM     (0..x))

BASEOID="1.3.6.1.4.1.21796.4.9.3.1"

SENSORS_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.4 |  grep -v "No Such Object" | sed 's/.*\"\(.*\)\"/\1/g'`)
IFS=$IFS_NEWLINE
SENSORS_NAME=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2 |  grep -v "No Such Object" | sed 's/.*\"\(.*\)\"/\1/g'`)

  [ ! "$SENSORS_NAME" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$SENSORS_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  for INDEX in "${!SENSORS_VALUE[@]}" ; do
    if [ "${SENSORS_NAME[$INDEX]}" == "Flood" ] ; then
      #echo "${SENSORS_NAME[$INDEX]} ${SENSORS_VALUE[$INDEX]}"
	if [ ${SENSORS_VALUE[$INDEX]} -ne 0 ] ; then
	  STATUS_CRITICAL=1
	fi
    fi
  done

IFS=$IFS_CURRENT

echo -n "Flood sensor "

  if [ $STATUS_CRITICAL ] ; then
    echo -e "CRITICAL"
    EXIT=2
  else
    echo -e "OK"
    EXIT=0
  fi

exit $EXIT
