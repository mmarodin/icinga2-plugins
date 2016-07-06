#!/bin/sh
#--------
# Check QNAP RAID Volume usage script for Icinga2
# Require: net-snmp-utils, bc
# v.20160420 by mmarodin
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
        echo "Useage: check_qnap_volume.sh -H hostname -C community -w warn -c crit"
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
  [ -z $WARN ] && WARN=20
  [ -z $CRIT ] && CRIT=10

DISK=`snmpwalk -c $COMM -v $VERS $HOST 1.3.6.1.4.1.24681.1.2.17.1.4.1 | awk '{print $4}' | sed 's/.\(.*\)/\1/'`
FREE=`snmpwalk -c $COMM -v $VERS $HOST 1.3.6.1.4.1.24681.1.2.17.1.5.1 | awk '{print $4}' | sed 's/.\(.*\)/\1/'`
DISKUNIT=`snmpwalk -c $COMM -v $VERS $HOST 1.3.6.1.4.1.24681.1.2.17.1.4.1 | awk '{print $5}' | sed 's/\(.*\)./\1/'`
FREEUNIT=`snmpwalk -c $COMM -v $VERS $HOST 1.3.6.1.4.1.24681.1.2.17.1.5.1 | awk '{print $5}' | sed 's/\(.*\)./\1/'`

  [ ! $DISK ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! $FREE ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! $DISKUNIT ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! $FREEUNIT ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  [ "$DISKUNIT" == "TB" ] && DISK=`echo "scale=0; $DISK*1024*1024" | bc -l`
  [ "$DISKUNIT" == "GB" ] && DISK=`echo "scale=0; $DISK*1024" | bc -l`
  [ "$FREEUNIT" == "TB" ] && FREE=$(echo "scale=0; $FREE*1024*1024" | bc -l)
  [ "$FREEUNIT" == "GB" ] && FREE=$(echo "scale=0; $FREE*1024" | bc -l)

USED=`echo "scale=0; $DISK-$FREE" | bc -l`
PERC=`echo "scale=0; $FREE*100/$DISK" | bc -l`

DISK=`echo "scale=0; $DISK/1024" | bc -l`
FREE=`echo "scale=0; $FREE/1024" | bc -l`
USED=`echo "scale=0; $USED/1024" | bc -l`

CRITGB=`echo "scale=0; $DISK * (100 - $CRIT) / 100" | bc -l`
WARNGB=`echo "scale=0; $DISK * (100 - $WARN) / 100" | bc -l`
#OUTPUT="total:"$DISK"GB - used:"$USED"GB - free:"$FREE"GB = $PERC% | '/share/MD0_DATA'=$PERC;$WARN;$CRIT;0;100"
OUTPUT=" | '/share/MD0_DATA'=$USED;$WARNGB;$CRITGB;0;$DISK"
#DISK CRITICAL - free space /share/MD0_DATA 421 GB (5%)  | '/share/MD0_DATA'=7821;6594;7418;0;82433

echo -n "DISK "
  if [ $USED -ge $CRITGB ]; then
    echo -n "CRITICAL"
    EXIT=2
  elif [ $USED -ge $WARNGB ]; then
    echo -n "WARNING"
    EXIT=1
  else 
    echo -n " - temp $USED - $FREE - OK"
    EXIT=0
  fi
echo " - free space /share/MD0_DATA $FREE GB ($PERC%) | '/share/MD0_DATA'="$USED"GB;"$WARNGB";"$CRITGB";0;"$DISK
exit $EXIT
