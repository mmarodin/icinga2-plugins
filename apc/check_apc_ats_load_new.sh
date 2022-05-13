#!/bin/sh
#--------
# Check APC ATS load script for Icinga2
# Require: net-snmp-utils, bc
# v.20210701 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:h" optname ; do
    case "$optname" in
      "V")
        VERSC=$OPTARG
	  if [ "$VERSC" = "2c" ] ; then
	    VERS="2"
	  else
	    VERS=$VERSC
	  fi
        ;;
      "H")
        HOST=$OPTARG
        ;;
      "C")
        COMM=$OPTARG
        ;;
      "h")
        echo "Useage: check_apc_ats_load2.sh -H hostname -C community"
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

  [ -z $VERSC ] && VERSC="2c" && VERS="2"
  [ -z $HOST ] && echo "Please specify hostname!" && exit 2
  [ -z $COMM ] && echo "Please specify SNMP community!" && exit 2

IFS_CURRENT=$IFS
IFS_COMMA=","
IFS_NEWLINE="
"

#atsOutputCurrent		.1.3.6.1.4.1.318.1.1.8.5.4.3.1.4
#atsOutputPercentPower		.1.3.6.1.4.1.318.1.1.8.5.4.3.1.16

TOTAL_LOAD=`snmpwalk -c $COMM -v $VERSC $HOST .1.3.6.1.4.1.318.1.1.8.5.4.3.1.4 | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 } '`
PERC_POWER=`snmpwalk -c $COMM -v $VERSC $HOST .1.3.6.1.4.1.318.1.1.8.5.4.3.1.16 | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 } '`

  [ ! "$TOTAL_LOAD" ] && echo "No such device!" && exit 2
  [ ! "$PERC_POWER" ] && echo "No such device!" && exit 2

  [ $TOTAL_LOAD -lt 10 ] && TZERO="0"
  [ $PERC_POWER -lt 10 ] && PZERO="0"

  if [ $TOTAL_LOAD -ge 100 ] ; then
    STATUS_CRITICAL=1
  elif [ $TOTAL_LOAD -ge 80 ] ; then
    STATUS_WARNING=1
  else
    STATUS_OK=1
  fi
  if [ $PERC_POWER -ge 80 ] ; then
    STATUS_CRITICAL=1
  elif [ $PERC_POWER -ge 60 ] ; then
    STATUS_WARNING=1
  else
    STATUS_OK=1
  fi

TOTAL_LOAD=`echo "$TOTAL_LOAD * 0.10" | bc -l`
PERC_POWER=`echo "$PERC_POWER * 0.10" | bc -l`
TOTAL_LOAD="$TZERO$TOTAL_LOAD"
PERC_POWER="$PZERO$PERC_POWER"

  [ $STATUS_OK ] && STATUS="OK" && EXIT=0
  [ $STATUS_WARNING ] && STATUS="WARNING" && EXIT=1
  [ $STATUS_CRITICAL ] && STATUS="CRITICAL" && EXIT=2

echo $STATUS": Total Load "$TOTAL_LOAD"A - Capacity "$PERC_POWER"% | 'total_load'=$TOTAL_LOAD;8;10;0 'perc_capacity'=$PERC_POWER;60;80;0"
exit $EXIT
