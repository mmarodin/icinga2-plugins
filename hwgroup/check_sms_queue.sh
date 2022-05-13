#!/bin/sh
#--------
# Check HWGroup SMSgw queue script for Icinga2
# Require: net-snmp-utils, bc
# v.20210906 by mmarodin
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
        echo "Useage: check_sms_queue.sh -H hostname -C community -V version"
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

EXIT=0
IFS_CURRENT=$IFS
IFS_NEWLINE="
"
IFS=$IFS_NEWLINE

#.1.3.6.1.4.1.21796.4.10.1.7.0  Number of failures SMS		(integer, 0)
#.1.3.6.1.4.1.21796.4.10.1.10.0 Message queue length		(integer, 0)
#.1.3.6.1.4.1.21796.4.10.1.6.0  Number of SMS			(integer, 464)
#.1.3.6.1.4.1.21796.4.10.1.8.0  Number of Ringout		(integer, 460)
#.1.3.6.1.4.1.21796.4.10.1.9.0  Number of failures Ringout	(integer, 0)
BASEOID=".1.3.6.1.4.1.21796.4.10.1"
SMS_FAILED=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.7.0 |  grep -v "No Such Object" | sed 's/.*INTEGER: \(.*\)/\1/g'`)
SMS_QUEUED=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.10.0 |  grep -v "No Such Object" | sed 's/.*INTEGER: \(.*\)/\1/g'`)
SMS_SENT=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.6.0 |  grep -v "No Such Object" | sed 's/.*INTEGER: \(.*\)/\1/g'`)
RING_DONE=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.8.0 |  grep -v "No Such Object" | sed 's/.*INTEGER: \(.*\)/\1/g'`)
RING_FAILED=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.9.0 |  grep -v "No Such Object" | sed 's/.*INTEGER: \(.*\)/\1/g'`)

  [ ! "$SMS_FAILED" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$SMS_QUEUED" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  if [ $SMS_FAILED -gt 0 ] ; then
    TEXT="$SMS_FAILED SMS not sent"
    EXIT=1
  fi
  #if [ $SMS_QUEUED -gt 0 ] ; then
  if [ $SMS_QUEUED -gt 3 ] ; then
    TEXT="$SMS_QUEUED SMS on queue"
    EXIT=2
  fi
  if [ $EXIT -eq 0 ] ; then
    TEXT="SMS queue is OK"
  fi

IFS=$IFS_CURRENT

echo "$TEXT | sms_failed=$SMS_FAILED sms_queued=$SMS_QUEUED sms_sent=$SMS_SENT ring_done=$RING_DONE ring_failed=$RING_FAILED"
exit $EXIT
