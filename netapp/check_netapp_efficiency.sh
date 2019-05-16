#!/bin/sh
#--------
# Check Netapp Storage Efficiency script for Icinga2
# Require: expect 'check_netapp_efficiency' script
# v.20190301 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

 while getopts ":H:u:p:h" optname ; do
    case "$optname" in
      "H")
        HOST=$OPTARG
        ;;
      "u")
        USER=$OPTARG
        ;;
      "p")
        PASS=$OPTARG
        ;;
      "h")
        echo "Useage: check_netapp_efficiency.sh -H hostname -u user -p password"
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
  [ -z $USER ] && echo "Please specify username!" && exit 2
  [ -z $PASS ] && echo "Please specify password!" && exit 2

EXSCRIPT="/opt/scripts/icinga2/check_netapp_efficiency.exp"
FILE="/tmp/tmp_icinga2_efficiency.$HOST"

$EXSCRIPT $HOST $USER $PASS >/dev/null 2>&1

  [ ! -e $FILE ] && echo "Execution problem, probably hostname did not respond!" && exit 2

AGGR_LIST=(`cat $FILE | grep "Aggregate\:" | awk '{ print $2 }' | sed 's/\r//g'`)
SEFF_LIST=(`cat $FILE | grep "Total Data Reduction Ratio\:" | awk '{ print $5 }' | sed 's/\r//g'`)

  if [ $AGGR_LIST ] ; then
    echo -n "Storage efficiency "
      for i in ${!AGGR_LIST[@]} ; do
	TEXT=$TEXT${AGGR_LIST[i]}": "${SEFF_LIST[i]}" "
	PERFDATA=$PERFDATA" '"${AGGR_LIST[i]}"'=`echo ${SEFF_LIST[i]} | awk 'BEGIN { FS = ":" } { print $1 }'`"
      done
    echo "$TEXT|$PERFDATA"
    EXIT=0
  else
    echo "Execution problem, something went wrong!"
    EXIT=2
  fi

exit $EXIT
