#!/bin/sh
#--------
# Check VISA controller mode script for Icinga2
# Require: net-snmp-utils, bc
# v.20210630 by mmarodin
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
        echo "Useage: check_visa_mode.sh -H hostname -C community -V version"
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

# pControllerMode
#.1.3.6.1.4.1.28634.17.4.8315			(INTEGER: 2)

MODE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.28634.17.4.8315 | grep -v "No Such Object" | sed 's/SNMPv2-SMI::enterprises.28634.17.4.8315.0 = INTEGER: \(.*\)/\1/g'`)

  [ ! "$MODE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  case "$MODE" in
    "0")
      TEXT="OFF"
      EXIT=2
      ;;
    "1")
      TEXT="MAN"
      EXIT=1
      ;;
    "2")
      TEXT="AUTO"
      EXIT=0
      ;;
    "3")
      TEXT="TEST"
      EXIT=1
      ;;
    *)
    # Should not occur
      echo "Unknown error while processing options"
      exit 1
      ;;
  esac

echo -n "Controller Mode "
  if [ $EXIT -eq 0 ] ; then
    echo -n "OK"
  elif [ $EXIT -eq 1 ] ; then
    echo -n "WARNING"
  else
    echo -n "CRITICAL"
  fi
echo -e ": $TEXT"
exit $EXIT
