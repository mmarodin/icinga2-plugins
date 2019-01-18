#!/bin/sh
#--------
# Check Aerohive temperature script for Icinga2
# Require: bc, expect 'check_aerohive_temp.exp' script
# v.20181108 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":H:p:w:c:h" optname ; do
    case "$optname" in
      "H")
        HOST=$OPTARG
        ;;
      "p")
        PASS=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "w")
        WARN=$OPTARG
        ;;
      "h")
        echo "Useage: check_aerohive_temp.sh -H hostname -p password -w warn -c crit"
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

  [ -z $HOST ] && echo "Please specify hostname!" && exit 2
  [ -z $PASS ] && echo "Please specify password!" && exit 2
  [ -z $WARN ] && WARN=60
  [ -z $CRIT ] && CRIT=65

EXSCRIPT="/opt/scripts/icinga2/check_aerohive_temp.exp"
FILE="/tmp/tmp_icinga2_temp.$HOST"

$EXSCRIPT $HOST $PASS >/dev/null 2>&1

  [ ! -e $FILE ] && echo "Execution problem, probably hostname did not respond!" && exit 2

TEMPERATURE=`cat $FILE | grep "Current temperature" | sed 's/.*  \(.*\)(degree C)/\1/g' | sed 's/\r//g'`

echo -n "Temperature "

  if [ $TEMPERATURE -ge $CRIT ] ; then
    echo -n "CRITICAL"
    EXIT=1
  elif [ $TEMPERATURE -ge $WARN ] ; then
    echo -n "WARNING"
    EXIT=2
  else
    echo -n "OK"
    EXIT=0
  fi
echo " - celsius $TEMPERATURE | 'celsius'=$TEMPERATURE;$WARN;$CRIT"

rm -f $FILE
exit $EXIT
