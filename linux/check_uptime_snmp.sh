#!/bin/sh
#--------
# Check uptime of network devices via SNMP, converting timeticks to perfdata in seconds,
# script for Icinga2
# Require: net-snmp-utils, bc
# v.20210324 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:o:c:m:h" optname ; do
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
      "o")
        OID=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "m")
        MODEL=$OPTARG
        ;;
      "h")
        echo "Useage: check_uptime_snmp.sh -H hostname -V version -C community -o oid -c crit [-m model]"
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
  [ -z $OID ] && OID="1.3.6.1.2.1.1.3.0"
  [ -z $CRIT ] && CRIT=86400

OUTPUT=`snmpwalk -c $COMM -v $VERS $HOST $OID | awk 'BEGIN { FS = "= " } { print $2 }'`
  [ ! "$OUTPUT" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
TIMETICKS=`echo $OUTPUT | sed 's/.*(\(.*\)).*/\1/'`
  if [ "$MODEL" == "lantech" ] ; then
    SECONDS=$TIMETICKS
  else
    SECONDS=`echo "scale=0; $TIMETICKS / 100" | bc -l`
    #HOURS=`echo "scale=0; $TIMETICKS / 360000" | bc -l`
    #DAYS=`echo "scale=0; $TIMETICKS / 8640000" | bc -l`
  fi

echo -n "SNMP "

  [ $SECONDS -lt $CRIT ] && EXIT=2 && echo -n "CRITICAL" || echo -n "OK"

echo " - "$OUTPUT" | 'uptime'="$SECONDS"s;;;"
exit $EXIT
