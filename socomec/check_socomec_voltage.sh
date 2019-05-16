#!/bin/sh
#--------
# Check Socomec Netvision/RTvision input/output voltages script for Icinga2
# Require: net-snmp-utils, bc
# v.20190516 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:m:h" optname ; do
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
      "m")
        MODE=$OPTARG
        ;;
      "h")
        echo "Useage: check_socomec_voltage.sh -H hostname -V version -C community -m [net|rt]"
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
  [ -z $MODE ] && MODE="net"

  if [ "$MODE" == "rt" ] ; then
    VOLTIN="1.3.6.1.4.1.2254.2.4.4.3"
    VOLTOUT="1.3.6.1.4.1.2254.2.4.5.4"
  else
    VOLTIN="1.3.6.1.4.1.4555.1.1.1.1.3.3.1.2.1"
    VOLTOUT="1.3.6.1.4.1.4555.1.1.1.1.4.4.1.2.1"
  fi

IN=`snmpwalk -v$VERS -c $COMM $HOST $VOLTIN | grep -v "No Such Object" | awk '{print $4}'`
OUT=`snmpwalk -v$VERS -c $COMM $HOST $VOLTOUT | grep -v "No Such Object" | awk '{print $4}'`

  [ ! "$IN" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$OUT" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

IN=`echo "scale=0; $IN / 10" | bc`
OUT=`echo "scale=0; $OUT / 10" | bc`

echo "OK: Input voltage: "$IN"V - Output voltage: "$OUT"V | 'voltage_in'="$IN";;; 'voltage_out'="$OUT";;;"
exit $EXIT
