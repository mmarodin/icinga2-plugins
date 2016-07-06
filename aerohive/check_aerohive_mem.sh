#!/bin/sh
#--------
# Check Aerohive memory script for Icinga2
# Require: bc, expect 'check_aerohive_mem.exp' script
# v.20160412 by mmarodin
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
        echo "Useage: check_aerohive_mem.sh -H hostname -p password -w warn -c crit"
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
  [ -z $WARN ] && WARN=85
  [ -z $CRIT ] && CRIT=95

EXSCRIPT="/opt/scripts/icinga2/check_aerohive_mem.exp"
FILE="/tmp/tmp_icinga2_mem.$HOST"

$EXSCRIPT $HOST $PASS >/dev/null 2>&1

  [ ! -e $FILE ] && echo "Execution problem, probably hostname did not respond!" && exit 2

MEM_USED=`cat $FILE | grep Used | awk '{print $3}'`
MEM_TOTAL=`cat $FILE | grep Total | awk '{print $3}'`
MEM_FREE=`cat $FILE | grep Free | awk '{print $3}'`

MEM_CRIT=`echo "scale=0;$(expr $MEM_TOTAL / 100) * $CRIT" | bc`
MEM_WARN=`echo "scale=0;$(expr $MEM_TOTAL / 100) * $WARN" | bc`
USAGE=`echo "scale=2 ; $MEM_USED / $MEM_TOTAL * 100" | bc`

echo -n "RAM:$USAGE% - "
  if [ $MEM_USED -ge $MEM_CRIT ] ; then
    echo -n "CRITICAL"
    EXIT=1
  elif [ $MEM_USED -ge $MEM_WARN ] ; then
    echo -n "WARNING"
    EXIT=2
  else
    echo -n "OK"
    EXIT=0
  fi
echo " | 'ram_used'="$MEM_USED"KB;"$MEM_WARN";"$MEM_CRIT";0;"$MEM_TOTAL
exit $EXIT
