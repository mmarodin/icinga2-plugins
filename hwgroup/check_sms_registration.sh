#!/bin/sh
#--------
# Check HWGroup SMSgw mobile network status script for Icinga2
# Require: net-snmp-utils, bc
# v.20210811 by mmarodin
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
        echo "Useage: check_sms_registration.sh -H hostname -C community -V version"
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

IFS_CURRENT=$IFS
IFS_NEWLINE="
"
IFS=$IFS_NEWLINE

#.1.3.6.1.4.1.21796.4.10.1.2.0 Modem Network Registration	(string, Registered, home network)
STATUS=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.21796.4.10.1.2.0 |  grep -v "No Such Object" | sed 's/.*\"\(.*\)\"/\1/g'`)

  [ ! "$STATUS" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  if [ "$STATUS" == "Registered, home network" ] ; then
    TEXT="OK"
    EXIT=0
  else
    TEXT="CRITICAL"
    EXIT=2
  fi

IFS=$IFS_CURRENT

echo "Modem Network Registration is $TEXT"
exit $EXIT
