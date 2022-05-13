#!/bin/sh
#--------
# Check APC ATS load script for Icinga2
# Require: net-snmp-utils, bc
# v.20160407 by mmarodin
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
        echo "Useage: check_apc_ats_load.sh -H hostname -C community"
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

#ATS_OID="1.3.6.1.4.1.318.1.1.8.5.4.5.1.4"
#PDU_OID=".1.3.6.1.4.1.318.1.1.12.2.3.1.1.2"

AMPS=`snmpwalk -c $COMM -v $VERSC $HOST 1.3.6.1.4.1.318.1.1.8.5.4.5.1.4 | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 } '`

  [ ! "$AMPS" ] && echo "No such device!" && exit 2

TOTAL_LOAD=`echo $AMPS | awk '{ print $1 }'`
BANK_B1_LOAD=`echo $AMPS | awk '{ print $2 }'`
BANK_B2_LOAD=`echo $AMPS | awk '{ print $3 }'`
#TOTAL_LOAD=`echo "$(echo $AMPS | awk '{ print $1 }') * 0.10" | bc -l`
#BANK_B1_LOAD=`echo "$(echo $AMPS | awk '{ print $2 }') * 0.10" | bc -l`
#BANK_B2_LOAD=`echo "$(echo $AMPS | awk '{ print $3 }') * 0.10" | bc -l`

  if [ $TOTAL_LOAD -ge 320 ] ; then
    STATUS_CRITICAL=1
  elif [ $TOTAL_LOAD -ge 280 ] ; then
    STATUS_WARNING=1
  else
    STATUS_OK=1
  fi
  if [ $BANK_B1_LOAD -ge 160 ] ; then
    STATUS_CRITICAL=1
  elif [ $BANK_B1_LOAD -ge 120 ] ; then
    STATUS_WARNING=1
  else
    STATUS_OK=1
  fi
  if [ $BANK_B2_LOAD -ge 160 ] ; then
    STATUS_CRITICAL=1
  elif [ $BANK_B2_LOAD -ge 120 ] ; then
    STATUS_WARNING=1
  else
    STATUS_OK=1
  fi

TOTAL_LOAD=`echo "$TOTAL_LOAD * 0.10" | bc -l`
BANK_B1_LOAD=`echo "$BANK_B1_LOAD * 0.10" | bc -l`
BANK_B2_LOAD=`echo "$BANK_B2_LOAD * 0.10" | bc -l`

  [ $STATUS_OK ] && STATUS="OK" && EXIT=0
  [ $STATUS_WARNING ] && STATUS="WARNING" && EXIT=1
  [ $STATUS_CRITICAL ] && STATUS="CRITICAL" && EXIT=2

echo "$STATUS: Total Load $TOTAL_LOAD A - Bank B1 Load $BANK_B1_LOAD A - Bank B2 Load $BANK_B2_LOAD A | 'total_load'=$TOTAL_LOAD;28;32;0 'bank_b1_load'=$BANK_B1_LOAD;12;16;0 'bank_b2_load'=$BANK_B2_LOAD;12;16;0"
exit $EXIT
