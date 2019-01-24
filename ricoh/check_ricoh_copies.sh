#!/bin/sh
#--------
# Check Ricoh copies status script for Icinga2
# Require: net-snmp-utils, bc, grep, sed
# v.20181217 by mmarodin
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
        echo "Useage: check_ricoh_copies.sh -H hostname -C community -V version"
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

#.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.3	Counter:Copy:Black & White	(integer, NUM)
#.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.4	Counter:Copy:Single/Two-color	(integer, NUM)
#.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.5	Counter:Copy:Full Color		(integer, NUM)
#.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.7	Counter:FAX:Black & White	(integer, NUM)
#.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.9	Counter:Print:Black & White	(integer, NUM)
#.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.10	Counter:Print:Single/Two-col.	(integer, NUM)
#.1.3.6.1.4.1.367.3.2.1.2.19.5.1.9.11	Counter:Print:Full Color	(integer, NUM)
#.1.3.6.1.4.1.367.3.2.1.2.19.1.0	Total Count			(integer, NUM)
#.1.3.6.1.4.1.367.3.2.1.6.1.1.7.1	Name				(string, VALUE)
#.1.3.6.1.4.1.367.3.2.1.6.1.1.8.1	Position			(string, VALUE)

#BASEOID="1.3.6.1.4.1.367.3.2.1.2.19"
BASEOID="1.3.6.1.4.1.367.3.2.1"

COPY_BW=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.19.5.1.9.3 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
COPY_ST=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.19.5.1.9.4 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
COPY_FC=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.19.5.1.9.5 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
FAX_BW=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.19.5.1.9.7 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
PRINT_BW=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.19.5.1.9.9 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
PRINT_ST=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.19.5.1.9.10 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
PRINT_FC=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.19.5.1.9.11 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
TOTAL=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.19.1.0 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
NAME=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.6.1.1.7.1 | grep -v "No Such Instance" | sed 's/.*\"\(.*\)\"/\1/g'`
POSITION=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.6.1.1.8.1 | grep -v "No Such Instance" | sed 's/.*\"\(.*\)\"/\1/g'`

  [ ! "$TOTAL" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$POSITION" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

BW_TOTAL=`expr $COPY_BW + $PRINT_BW + $FAX_BW | bc`
TEXT="$NAME ($POSITION) - Total $TOTAL, Black/White $BW_TOTAL"
LAST="'total'=$TOTAL 'bw'=$BW_TOTAL"

  if [[ $COPY_ST && $COPY_FC && $PRINT_ST && $PRINT_FC ]]; then
    C_TOTAL=`expr $COPY_ST + $COPY_FC + $PRINT_ST + $PRINT_FC | bc`
    TEXT="$TEXT, Color $C_TOTAL"
    LAST="$LAST 'color'=$C_TOTAL"
  else
    C_TOTAL=0
  fi

CHECK_TOTAL=`expr $BW_TOTAL + $C_TOTAL | bc`
  [ $CHECK_TOTAL -ne $TOTAL ] && STATUS_CRITICAL=1

echo -n "Copies "

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

echo -n " - $TEXT"
echo -e " | $LAST"
exit $EXIT
