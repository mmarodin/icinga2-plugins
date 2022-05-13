#!/bin/sh
#--------
# Check HWGroup STE2 temperature and humidity status script for Icinga2
# Require: net-snmp-utils, bc
# v.20210813 by mmarodin
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
        echo "Useage: check_ste2_temp.sh -H hostname -C community -V version -w warn -c crit"
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
#  [ -z $WARN ] && WARN="50 45 45"
#  [ -z $CRIT ] && CRIT="60 55 55"

WARN=(`echo $WARN`)
CRIT=(`echo $CRIT`)
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
    if [[ "${SENSORS_NAME[$INDEX]}" = "Temp"* ]] || [[ "${SENSORS_NAME[$INDEX]}" = "Hum"* ]] ; then
      TEXT="$TEXT - ${SENSORS_NAME[$INDEX]} ${SENSORS_VALUE[$INDEX]}"
      SENSOR_ROUND=`echo "scale=0; ${SENSORS_VALUE[$INDEX]}" / 1 | bc`
        
        if [[ ${CRIT[$INDEX]} = *":"* ]] ; then
	        CRIT_MIN=`echo  ${CRIT[$INDEX]} | awk 'BEGIN { FS = ":" } { print $1 }'`
	        CRIT_MAX=`echo  ${CRIT[$INDEX]} | awk 'BEGIN { FS = ":" } { print $2 }'`
        else
	        CRIT_MAX=${CRIT[$INDEX]}
        fi

        if [[ ${WARN[$INDEX]} = *":"* ]] ; then
	        WARN_MIN=`echo  ${WARN[$INDEX]} | awk 'BEGIN { FS = ":" } { print $1 }'`
	        WARN_MAX=`echo  ${WARN[$INDEX]} | awk 'BEGIN { FS = ":" } { print $2 }'`
        else
	        WARN_MAX=${WARN[$INDEX]}
        fi

      #echo "- $INDEX - ${SENSORS_VALUE[$INDEX]} - $CRIT_MIN - $CRIT_MAX - $WARN_MIN - $WARN_MAX -"
      #read a

      LAST="$LAST ${SENSORS_NAME[$INDEX]// /_}=${SENSORS_VALUE[$INDEX]};$WARN_MAX;$CRIT_MAX"
        [ $CRIT_MIN ] && LAST="$LAST;$CRIT_MIN;$CRIT_MAX"

        if [ "$CRIT_MIN" != "" ] ; then
	    if [ $SENSOR_ROUND -ge $CRIT_MAX ] || [ $SENSOR_ROUND -le $CRIT_MIN ] ; then
	      TEXT_CRIT="$TEXT_CRIT - ${SENSORS_NAME[$INDEX]} ${SENSORS_VALUE[$INDEX]}"
	      STATUS_CRITICAL=1
	      unset CRIT_MIN
	      continue
	    fi
        else
	    if [ $SENSOR_ROUND -ge $CRIT_MAX ] ; then
	      TEXT_CRIT="$TEXT_CRIT - ${SENSORS_NAME[$INDEX]} ${SENSORS_VALUE[$INDEX]}"
	      STATUS_CRITICAL=1
	      continue
	    fi
        fi

      unset CRIT_MIN

        if [ "$WARN_MIN" != "" ] ; then
	    if [ $SENSOR_ROUND -ge $WARN_MAX ] || [ $SENSOR_ROUND -le $WARN_MIN ] ; then
	      TEXT_CRIT="$TEXT_CRIT - ${SENSORS_NAME[$INDEX]} ${SENSORS_VALUE[$INDEX]}"
	      STATUS_WARNING=1
	      unset WARN_MIN
	    fi
        else
            if [ $SENSOR_ROUND -ge $WARN_MAX ] ; then
	      TEXT_CRIT="$TEXT_CRIT - ${SENSORS_NAME[$INDEX]} ${SENSORS_VALUE[$INDEX]}"
	      STATUS_WARNING=1
	    fi
        fi
  
      unset WARN_MIN
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
