#!/bin/sh
#--------
# Check VISA load script for Icinga2
# Require: net-snmp-utils, bc
# v.20210514 by mmarodin
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
        echo "Useage: check_visa_load.sh -H hostname -C community -V version -w warn -c crit"
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
  [ -z $WARN ] && WARN="30"
  [ -z $CRIT ] && CRIT="40"

# vLoadKW
#.1.3.6.1.4.1.28634.17.2.8202		(INTEGER: 0)
# vLoadKWL1
#.1.3.6.1.4.1.28634.17.2.8524           (INTEGER: 0)
# vLoadKWL2
#.1.3.6.1.4.1.28634.17.2.8525           (INTEGER: 0)
# vLoadKWL3
#.1.3.6.1.4.1.28634.17.2.8526           (INTEGER: 0)

LOADKW=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.28634.17.2.8202 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.28634.17.2.8202.0 = INTEGER: \(.*\)/\1/g'`)
LOADKWL1=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.28634.17.2.8524 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.28634.17.2.8524.0 = INTEGER: \(.*\)/\1/g'`)
LOADKWL2=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.28634.17.2.8525 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.28634.17.2.8525.0 = INTEGER: \(.*\)/\1/g'`)
LOADKWL3=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.28634.17.2.8526 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.28634.17.2.8526.0 = INTEGER: \(.*\)/\1/g'`)


  [ ! "$LOADKW" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  if [ $LOADKW -gt $CRIT ] ; then
    TEXT="CRITICAL"
    EXIT=2
  elif [ $LOADKW -gt $WARN ] ; then
    TEXT="WARNING"
    EXIT=1
  else
    TEXT="OK"
    EXIT=0
  fi

echo "Load level $TEXT: "$LOADKW"kW | loadkw=$LOADKW loadkwL1=$LOADKWL1 loadkwL2=$LOADKWL2 loadkwL3=$LOADKWL3"
exit $EXIT
