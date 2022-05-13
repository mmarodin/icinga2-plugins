#!/bin/sh
#--------
# Check VISA engine state script for Icinga2
# Require: net-snmp-utils, bc
# v.20210513 by mmarodin
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
        echo "Useage: check_visa_engine.sh -H hostname -C community -V version"
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

# vEngineState
#.1.3.6.1.4.1.28634.17.2.9244			(INTEGER: 1)

STATE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.28634.17.2.9244 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.28634.17.2.9244.0 = INTEGER: \(.*\)/\1/g'`)

  [ ! "$STATE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  case "$STATE" in
    "0")
      TEXT="Init"
      EXIT=1
      ;;
    "1")
      TEXT="Ready"
      EXIT=0
      ;;
    "2")
      TEXT="NotReady"
      EXIT=2
      ;;
    "3")
      TEXT="Prestart"
      EXIT=1
      ;;
    "4")
      TEXT="Cranking"
      EXIT=1
      ;;
    "5")
      TEXT="Pause"
      EXIT=1
      ;;
    "6")
      TEXT="Starting"
      EXIT=1
      ;;
    "7")
      TEXT="Running"
      EXIT=1
      ;;
    "8")
      TEXT="Loaded"
      EXIT=1
      ;;
    "9")
      TEXT="SoftUnld"
      EXIT=1
      ;;
    "10")
      TEXT="Cooling"
      EXIT=1
      ;;
    "11")
      TEXT="Stop"
      EXIT=1
      ;;
    "12")
      TEXT="Shutdown"
      EXIT=1
      ;;
    "13")
      TEXT="Ventil"
      EXIT=1
      ;;
    "14")
      TEXT="EmergMan"
      EXIT=2
      ;;
    "15")
      TEXT="SoftLoad"
      EXIT=1
      ;;
    "16")
      TEXT="WaitStop"
      EXIT=1
      ;;
    "17")
      TEXT="SDVentil"
      EXIT=1
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options"
      exit 1
      ;;
  esac

echo -n "Engine state "
  if [ $EXIT -eq 0 ] ; then
    echo -n "OK"
  elif [ $EXIT -eq 1 ] ; then
    echo -n "WARNING"
  else
    echo -n "CRITICAL"
  fi
echo -e ": $TEXT"
exit $EXIT
