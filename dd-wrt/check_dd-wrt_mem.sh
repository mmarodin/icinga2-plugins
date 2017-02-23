#!/bin/sh
#--------
# Check DD-WRT memory script for Icinga2
# Require: bc
# v.20160908 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:C:H:w:c:h" optname ; do
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
        echo "Useage: check_dd-wrt_mem.sh -H hostname -p password -w warn -c crit"
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
  [ -z $COMM ] && echo "Please specify SNMP community!" && exit 2
  [ -z $HOST ] && echo "Please specify hostname!" && exit 2
  [ -z $WARN ] && WARN=85
  [ -z $CRIT ] && CRIT=95

MEM_TOTAL=`snmpwalk -v$VERS -c $COMM $HOST 1.3.6.1.2.1.25.2.3.1.5.101 | awk '{ print $4 }'`
MEM_USED=`snmpwalk -v$VERS -c $COMM $HOST 1.3.6.1.2.1.25.2.3.1.6.101 | awk '{ print $4 }'`

  [ -z $MEM_TOTAL ] && exit 2
  [ "$MEM_TOTAL" == "Such" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ -z $MEM_USED ] && exit 2
  [ "$MEM_USED" == "Such" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

#MEM_CRIT=`echo "scale=0;$(expr $MEM_TOTAL / 100) * $CRIT" | bc`
#MEM_WARN=`echo "scale=0;$(expr $MEM_TOTAL / 100) * $WARN" | bc`

USAGE=`echo "scale=2 ; $MEM_USED / $MEM_TOTAL * 100" | bc`

echo -n "RAM:$USAGE% - "
#  if [ $MEM_USED -ge $MEM_CRIT ] ; then
#    echo -n "CRITICAL"
#    EXIT=1
#  elif [ $MEM_USED -ge $MEM_WARN ] ; then
#    echo -n "WARNING"
#    EXIT=2
#  else
    echo -n "OK"
    EXIT=0
#  fi
echo " | 'ram_used'="$MEM_USED"KB;"$MEM_WARN";"$MEM_CRIT";0;"$MEM_TOTAL
exit $EXIT