#!/bin/sh
#--------
# Check Aerohive interface/ssid script for Icinga2
# Require: net-snmp-utils, bc, manubulon SNMP plugin 'check_snmp_int.pl'
# v.20160414 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

 while getopts ":V:H:C:i:d:w:c:h" optname ; do
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
      "i")
        INT=$OPTARG
        ;;
      "d")
        DELAY=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "w")
        WARN=$OPTARG
        ;;
      "h")
        echo "Useage: check_aerohive_interface.sh -H hostname -p password -i interface -w warn -c crit -d delay"
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
  [ -z $INT ] && echo "Please specify interface!" && exit 2
  [ -z $DELAY ] && DELAY=60
  [ -z $WARN ] && WARN="256000,256000"
  [ -z $CRIT ] && CRIT="512000,512000"

IFS_CURRENT=$IFS
IFS_COMMA=","
IFS_NEWLINE="
"
MANUBULON="/usr/lib64/nagios/plugins/check_snmp_int.pl"
COUNTUP=0
COUNTDOWN=0

INTERFACES=`snmpwalk -c $COMM -v $VERSC $HOST .1.3.6.1.4.1.26928.1.1.1.2.1.1.1.1 | grep -v "No Such Instance" | grep "$INT\." | sed 's/.*26928.1.1.1.2.1.1.1.1\(.*\)/\1/g' | sed 's/^\(.*\) = STRING: \(.*\)/\1,\2/g' | sed 's/"//g'`
#.15,wifi0.1
#.18,wifi0.2
#.19,wifi0.3
#.21,wifi0.4

  [ ! "$INTERFACES" ] && echo "No such interface!" && exit 2

IFS=$IFS_NEWLINE
  for SSID in `snmpwalk -c $COMM -v $VERSC $HOST .1.3.6.1.4.1.26928.1.1.1.2.1.1.1.2 | grep -v "No Such Instance" | sed 's/.*26928.1.1.1.2.1.1.1.2\(.*\)/\1/g' | sed 's/^\(.*\) = STRING: \(.*\)/\1,\2/g' | sed 's/"//g' | grep -v "N/A"` ; do
#.15,ssidname
    IFS=$IFS_COMMA
    MATCH=`echo $INTERFACES | grep $(echo $SSID | awk '{print $1}') | awk '{print $2}'`
#wifi0.1
    NAME=`echo $SSID | awk '{print $2}'`
#ssidname
    IFS=$IFS_CURRENT
      if [ $MATCH ] ; then
	VALUE_ORIG=`$MANUBULON -C $COMM -H $HOST -$VERS -t 5 -w $WARN -c $CRIT -d $DELAY -n $MATCH -r -f -B -k -Y --label 1`
#wifi0.1:UP (in=0.1Kbps/out=96.4Kbps):1 UP: OK | 'wifi0.1_in_bps'=106;256000000;512000000;0;10000000 'wifi0.1_out_bps'=96374;256000000;512000000;0;10000000
#wifi0.3:DOWN: 1 int NOK : CRITICAL
	  [ "$(echo $VALUE_ORIG | grep "int NOK")" ] && COUNTDOWN=`echo "$COUNTDOWN + 1" | bc` || COUNTUP=`echo "$COUNTUP + 1" | bc`
	VALUE_CHANGED=`echo ${VALUE_ORIG//$MATCH/$NAME\_$INT}`
#ssidname_wifi0:UP (in=0.1Kbps/out=96.4Kbps):1 UP: OK | 'ssidname_wifi0_in_bps'=106;256000000;512000000;0;10000000 'ssidname_wifi0_out_bps'=96374;256000000;512000000;0;10000000
#ssidname_wifi0:DOWN: 1 int NOK : CRITICAL
	FIRST=`echo $VALUE_CHANGED | awk 'BEGIN { FS = "|" } { print $1 }' | awk '{ print $1 $2}'`
#ssidname_wifi0:UP(in=0.0Kbps/out=92.7Kbps):1
#ssidname_wifi0:DOWN:1
	STATUS=`echo $VALUE_CHANGED | awk 'BEGIN { FS = "|" } { print $1 }' | awk '{ print $4}'`
#OK
#NOK
	  case "$STATUS" in
	    "OK")
	      STATUS_OK=1
	      ;;
	    "WARNING")
	      STATUS_WARNING=1
	      ;;
	    "CRITICAL")
	      STATUS_CRITICAL=1
	      ;;
	    "NOK")
	      STATUS_WARNING=1
	      ;;
	    *)
	      CHECK=1
	      ;;
	  esac
	LAST=`echo $VALUE_CHANGED | awk 'BEGIN { FS = "|" } { print $2 }'`
#'ssidname_wifi0_in_bps'=6;256000000;512000000;0;10000000 'ssidname_wifi0_out_bps'=92684;256000000;512000000;0;10000000
#
	OUTPUT="$OUTPUT${FIRST::-2}, "
	PERFDATA="$PERFDATA$LAST"
      fi
  done

  if [ $CHECK ] ; then
      [ "`echo $VALUE_ORIG | grep '(1 rows)'`" ] && echo "This is first run!" && exit 1
#No usable data on file (1 rows)
    echo "Maybe check out of delta-time!"
#No usable data on file (201 rows)
    echo $VALUE_ORIG
    exit 1
  fi

echo -n "${OUTPUT::-2}:($COUNTUP UP):"
  [ $COUNTDOWN -gt 0 ] && echo -n "($COUNTDOWN DOWN):"
echo -n " "
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
echo " |$PERFDATA"
exit $EXIT
