#!/bin/sh
#--------
# Check Aerohive load script for Icinga2
# Require: bc, expect 'check_aerohive_cpu.exp' script
# v.20160317 by mmarodin
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
        echo "Useage: check_aerohive_cpu.sh -H hostname -p password -w warn -c crit"
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

EXSCRIPT="/opt/scripts/icinga2/check_aerohive_cpu.exp"
FILE="/tmp/tmp_icinga2_cpu.$HOST"

$EXSCRIPT $HOST $PASS >/dev/null 2>&1

  [ ! -e $FILE ] && echo "Execution problem, probably hostname did not respond!" && exit 2

CPU_TOTAL_FLOAT=`cat $FILE | grep total | awk '{print $4}' | cut -c 1-5`
CPU_TOTAL_INT=`printf "%.0f\n" "$CPU_TOTAL_FLOAT"`

echo -n "CPU used:$CPU_TOTAL_FLOAT% "
  if [ $CPU_TOTAL_INT -ge $CRIT ] ; then
    echo -n "(>$CRIT%) - CRITICAL"
    EXIT=1
  elif [ $CPU_TOTAL_INT -ge $WARN ] ; then
    echo -n "(>$WARN%) - WARNING"
    EXIT=2
  else
    echo -n "(<$WARN%) - OK"
    EXIT=0
  fi
echo " | 'cpu_prct_used'=$CPU_TOTAL_FLOAT%;$WARN;$CRIT;0"
exit $EXIT
