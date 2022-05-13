#!/bin/sh
#--------
# Check Lantech load via SNMP
# script for Icinga2
# Require: net-snmp-utils, sed
# v.20210325 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:o:w:c:h" optname ; do
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
      "o")
        OID=$OPTARG
        ;;
      "w")
        WARN=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "h")
        echo "Useage: check_lantech_load.sh -H hostname -V version -C community -o oid [-c crit -w warn]"
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
  [ -z $OID ] && OID="1.3.6.1.4.1.37072.302.2.8.1.1.3"
  [ -z $WARN ] && WARN=85
  [ -z $CRIT ] && CRIT=95

LOADS=($(snmpwalk -c $COMM -v $VERS $HOST $OID | sed 's/.* = INTEGER: \(.*\)/\1/'))
  [ ! "$LOADS" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  for INDEX in {0..2}; do
    if [ ${LOADS[$INDEX]} -gt $CRIT ] ; then
      STATUS_CRITICAL=1
    elif [ ${LOADS[$INDEX]} -gt $WARN ] ; then
      STATUS_WARNING=1
    fi
  done

echo -n "LOAD "
  if [ $STATUS_CRITICAL ] ; then
    echo -n "CRITICAL"
  elif [ $STATUS_CRITICAL ] ; then
    echo -n "WARNING"
  else
    echo -n "OK"
  fi
echo -e " | load1=${LOADS[0]};$WARN;$CRIT load5=${LOADS[1]};$WARN;$CRIT load15=${LOADS[2]};$WARN;$CRIT"
exit $EXIT
