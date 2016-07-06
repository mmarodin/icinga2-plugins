#!/bin/sh
#--------
# Check QNAP Volume RAID status script for Icinga2
# Require: net-snmp-utils
# v.20160404 by mmarodin
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
      "h")
        echo "Useage: check_qnap_raid.sh -H hostname -C community"
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

STATE=`snmpwalk -c $COMM -v $VERS $HOST .1.3.6.1.4.1.24681.1.2.17.1.6.1 | awk '{print $4}' | sed 's/^"\(.*\).$/\1/'`
  if [ "$STATE" == "Ready" ] ; then
    echo "OK: $STATE"
    exit 0
  elif [ "$STATE" == "Rebuilding..." ] ; then
    echo "WARNING: $STATE"
    exit 1
  else
    echo "CRITICAL: $STATE"
    exit 2
  fi
