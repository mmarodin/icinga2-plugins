#!/bin/sh
#--------
# Check Aerohive connected clients script for Icinga2
# Require: net-snmp-utils, bc
# v.20160414 by mmarodin
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
        echo "Useage: check_aerohive_clients.sh -H hostname -p password -w warn -c crit"
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
  [ -z $WARN ] && WARN=25
  [ -z $CRIT ] && CRIT=35

IFS_CURRENT=$IFS
IFS_NEWLINE="
"
BGN_CLIENTS=0
AC_CLIENTS=0
TOTAL_CLIENTS=0

IFS=$IFS_NEWLINE
  for CLIENT in `snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.26928.1.1.1.2.1.2.1.13 | grep -v "No Such Object"` ; do
    CHANNEL=`echo $CLIENT | awk '{print $4}'`
      [ "$CHANNEL" == "Such" ] && break
    TOTAL_CLIENTS=`echo $TOTAL_CLIENTS + 1 | bc`
      if [ $CHANNEL -gt 11 ] ; then
        BGN_CLIENTS=`echo $BGN_CLIENTS + 1 | bc`
      else
        AC_CLIENTS=`echo $AC_CLIENTS +1 | bc`
      fi
  done
IFS=$IFS_CURRENT

  [ ! "$CLIENT" ] && exit 2

echo -n "clients "
  if [ $TOTAL_CLIENTS -ge $CRIT ] ; then
    echo -n "CRITICAL"
    EXIT=1
  elif [ $TOTAL_CLIENTS -ge $WARN ] ; then
    echo -n "WARNING"
    EXIT=2
  else
    echo -n "OK"
    EXIT=0
  fi
echo " - $TOTAL_CLIENTS currently connected | 'bgn_clients'=$BGN_CLIENTS 'ac_clients'=$AC_CLIENTS 'total_clients'=$TOTAL_CLIENTS;$WARN;$CRIT;0"
exit $EXIT
