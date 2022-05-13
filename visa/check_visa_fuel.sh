#!/bin/sh
#--------
# Check VISA fuel level script for Icinga2
# Require: net-snmp-utils, bc
# v.20210513 by mmarodin
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
        echo "Useage: check_visa_fuel.sh -H hostname -C community -V version -w warn -c crit"
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
  [ -z $WARN ] && WARN="70"
  [ -z $CRIT ] && CRIT="50"

# vFuelLevel
#.1.3.6.1.4.1.28634.17.2.9153			(INTEGER: 100)

FUEL=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.28634.17.2.9153 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.28634.17.2.9153.0 = INTEGER: \(.*\)/\1/g'`)

  [ ! "$FUEL" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  if [ $FUEL -lt $CRIT ] ; then
    TEXT="CRITICAL"
    EXIT=2
  elif [ $FUEL -lt $WARN ] ; then
    TEXT="WARNING"
    EXIT=1
  else
    TEXT="OK"
    EXIT=0
  fi

echo "Fuel level $TEXT: "$FUEL"% | fuel="$FUEL"%"
exit $EXIT
