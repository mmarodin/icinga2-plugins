#!/bin/sh
#--------
# Check Aironet interface/ssid/vlan script for Icinga2
# Require: net-snmp-utils, bc, expect 'check_aironet_interface.exp' script, manubulon SNMP 'check_snmp_int.pl' plugin
# v.20180403 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

 while getopts ":V:H:C:u:p:i:d:w:c:h" optname ; do
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
      "u")
        USER=$OPTARG
        ;;
      "p")
        PASS=$OPTARG
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
        echo "Useage: check_aerohive_interface.sh -H hostname -u user -p password -C community -V version -i interface -d delay -w warn -c crit"
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
  [ -z $USER ] && echo "Please specify username!" && exit 2
  [ -z $PASS ] && echo "Please specify password!" && exit 2
  [ -z $INT ] && echo "Please specify interface!" && exit 2
  [ -z $DELAY ] && DELAY=60
  [ -z $WARN ] && WARN="256000,256000"
  [ -z $CRIT ] && CRIT="512000,512000"

SSID=`snmpwalk -c $COMM -v $VERSC $HOST .1.3.6.1.4.1.9.9.272.1.1.1.6.1.2 | grep -v "No Such Instance" | sed 's/.*\"\(.*\)\"/\1/g'`
#SSIDNAME1
#SSIDNAME2

  [ ! "$SSID" ] && exit 2

INTERFACES="/tmp/tmp_icinga2_int.$HOST"
FIRMWARE=`snmpwalk -c $COMM -v $VERSC $HOST SNMPv2-MIB::sysDescr.0 | grep "12.4(21a)JA1"`
  if [ "$FIRMWARE" ] ; then
    #INTERFACES=`snmpwalk -c $COMM -v $VERSC $HOST .1.3.6.1.4.1.9.9.23.1.1.1.1.6 | grep -v "No Such Instance" | grep "Dot11Radio0\." | sed 's/.*\"\(.*\)\"/\1/g'`
    snmpwalk -c $COMM -v $VERSC $HOST .1.3.6.1.4.1.9.9.23.1.1.1.1.6 | grep -v "No Such Instance" | grep "Dot11Radio0\." | sed 's/.*\"\(.*\)\"/\1/g' > $INTERFACES
#Dot11Radio0.3
#Dot11Radio0.9
  else
    #INTERFACES=`snmpwalk -c $COMM -v $VERSC $HOST IF-MIB::ifDescr | grep -v "No Such Instance" | grep "Dot11Radio0\." | sed 's/.*STRING: \(.*\)/\1/g'`
    snmpwalk -c $COMM -v $VERSC $HOST IF-MIB::ifDescr | grep -v "No Such Instance" | grep "Dot11Radio0\." | sed 's/.*STRING: \(.*\)/\1/g' > $INTERFACES
  fi

EXSCRIPT="/opt/scripts/icinga2/check_aironet_interface.exp"
FILE="/tmp/tmp_icinga2_ssid.$HOST"
MANUBULON="/usr/lib64/nagios/plugins/check_snmp_int.pl"
COUNTUP=0
COUNTDOWN=0

  for NAME in `echo $SSID` ; do
    $EXSCRIPT $HOST $USER $PASS $NAME >/dev/null 2>&1
#show running-config ssid SSIDNAME1
#Building configuration...
#
#Current configuration:
#dot11 ssid SSIDNAME1
#   vlan 3
#   authentication open
#end
      [ ! -e $FILE.$NAME ] && echo "Execution problem, probably hostname did not respond!" && exit 2
    VLAN=`cat -e $FILE.$NAME | grep vlan | awk 'BEGIN { FS = " " } { print $2 }'`
#3^M$
    SUBINTERFACE=`echo $INT.${VLAN::-3}`
#Dot11Radio0.3
    #MATCH=`echo $INTERFACES | grep "$SUBINTERFACE"`
    MATCH=`cat $INTERFACES | grep "$SUBINTERFACE"`
#Dot11Radio0.3 Dot11Radio0.9
      if [ "$MATCH" ] ; then
        #VALUE_ORIG=`$MANUBULON -C $COMM -H $HOST -$VERS -t 5 -w $WARN -c $CRIT -d $DELAY -n $SUBINTERFACE -r -f -B -k -Y --label 1`
        VALUE_ORIG=`$MANUBULON -C $COMM -H $HOST -$VERS -t 5 -w $WARN -c $CRIT -d $DELAY -n "$MATCH" -r -f -B -k -Y --label 1`
#Dot11Radio0.3:UP (in=0.0Kbps/out=79.5Kbps):1 UP: OK | 'Dot11Radio0.3_in_bps'=0;256000000;512000000;0;54000000 'Dot11Radio0.3_out_bps'=79518;256000000;512000000;0;54000000
#Dot11Radio0.3:DOWN: 1 int NOK : CRITICAL
	  if [ ! "$FIRMWARE" ] ; then
	    VALUE_ORIG=`echo "${VALUE_ORIG//$MATCH/$SUBINTERFACE}"`
	  fi
	  [ "$(echo $VALUE_ORIG | grep "int NOK")" ] && COUNTDOWN=`echo "$COUNTDOWN + 1" | bc` || COUNTUP=`echo "$COUNTUP + 1" | bc`
        VALUE_CHANGED=`echo ${VALUE_ORIG//$SUBINTERFACE/$NAME\_$INT}`
#SSIDNAME1_Dot11Radio0:UP (in=0.0Kbps/out=79.5Kbps):1 UP: OK | 'SSIDNAME1_Dot11Radio0_in_bps'=0;256000000;512000000;0;54000000 'SSIDNAME1_Dot11Radio0_out_bps'=79518;256000000;512000000;0;54000000
        FIRST=`echo $VALUE_CHANGED | awk 'BEGIN { FS = "|" } { print $1 }' | awk '{ print $1 $2}'`
#SSIDNAME1_Dot11Radio0:UP(in=0.0Kbps/out=79.5Kbps):1
        STATUS=`echo $VALUE_CHANGED | awk 'BEGIN { FS = "|" } { print $1 }' | awk '{ print $4}'`
#OK
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
#'SSIDNAME1_Dot11Radio0_in_bps'=0;256000000;512000000;0;54000000 'SSIDNAME1_Dot11Radio0_out_bps'=79518;256000000;512000000;0;54000000
        OUTPUT="$OUTPUT${FIRST::-2}, "
        PERFDATA="$PERFDATA$LAST"
      fi
  done

  [ $COUNTUP -eq 0 ] && [ $COUNTDOWN -eq 0 ] && echo "No such interface!" && exit 2

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
