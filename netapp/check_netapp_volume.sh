#!/bin/sh
#--------
# Check Netapp RAID Volume usage script for Icinga2
# Require: net-snmp-utils, bc
# Without specifing volname always return OK state
#
# Known bugs and issues: volumes > 2Tb (SNMP problem)
#
# v.20160502 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:n:w:c:h" optname ; do
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
      "n")
        NAME=$OPTARG
        ;;
      "h")
        echo "Useage: check_netapp_volume.sh -H hostname -C community -V snmp_version -w warn -c crit -n volname"
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
  [ -z $WARN ] && WARN=20
  [ -z $CRIT ] && CRIT=10
  [ -z $NAME ] && NAME="vol"

BASEOID=".1.3.6.1.4.1.789.1.5.4.1"
#    dfFileSys               => { oid => '.1.3.6.1.4.1.789.1.5.4.1.2' },
#    dfKBytesTotal           => { oid => '.1.3.6.1.4.1.789.1.5.4.1.3' },
#    dfKBytesUsed            => { oid => '.1.3.6.1.4.1.789.1.5.4.1.4' },

  for VOLUME in `snmpwalk -c $COMM -v $VERS $HOST $BASEOID.2 | grep -v "No Such Instance" | grep -v aggr0 | grep -v ".snapshot" | grep -v "\.\." | grep $NAME | sed 's/.*.789.1.5.4.1.2.\(.*\)/\1/g' | sed 's/^\(.*\) = STRING: \(.*\)/\1,\2/g' | sed 's/"\(.*\)"/\1/' | sed 's/\(.*\)\/$/\1/'` ; do
    ID=`echo $VOLUME | awk 'BEGIN { FS = "," } { print $1 }'`
    VOLUME=`echo $VOLUME | awk 'BEGIN { FS = "," } { print $2 }'`
    TOTAL=`snmpwalk -c $COMM -v $VERS $HOST $BASEOID.3.$ID | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 }'`
    USED=`snmpwalk -c $COMM -v $VERS $HOST $BASEOID.4.$ID | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 }'`
    CRITICAL=`echo "scale=0; $TOTAL - ( $TOTAL * $CRIT / 100 )" | bc -l`
    WARNING=`echo "scale=0; $TOTAL -( $TOTAL * $WARN / 100 )" | bc -l`
    FREE=`echo "$TOTAL - $USED" | bc -l`
      [ $FREE -lt 1048576 ] && VALUE=`echo "$(echo "scale=2; $FREE / 1024" | bc -l) MB"` || VALUE=`echo "$(echo "scale=2; $FREE / 1024 / 1024" | bc -l) GB"`
    #echo "free space: $VOLUME $VALUE (`echo "scale=0; $FREE * 100 / $TOTAL" | bc -l`%) | '$VOLUME'="$USED"KB;"$WARNING";"$CRITICAL";0;"$TOTAL
    OUTPUT=$OUTPUT"$VOLUME $VALUE (`echo "scale=0; $FREE * 100 / $TOTAL" | bc -l`%): "
    #PERFDATA=$PERFDATA" '$VOLUME'="$USED"KB;"$WARNING";"$CRITICAL";0;"$TOTAL
    PERFDATA=$PERFDATA" '$VOLUME'=$(echo "scale=2; $USED / 1024" | bc -l)MB;$(echo "scale=2; $WARNING / 1024" | bc -l);$(echo "scale=2; $CRITICAL / 1024" | bc -l);0;$(echo "scale=2; $TOTAL / 1024" | bc -l)"
      if [ $USED -ge $CRITICAL ] ; then
	STATUS_CRITICAL=1
      elif [ $USED -ge $WARNING ] ; then
	STATUS_WARNING=1
      else
	STATUS_OK=1
      fi
  done

  [ ! "$VOLUME" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

echo -n "DISK "
  if [ "$NAME" == "vol" ] ; then
    #Always return OK state
    echo -n "STATUS"
    EXIT=0
  elif [ "$STATUS_CRITICAL" == "1" ] ; then
    echo -n "CRITICAL"
    EXIT=2
  elif [ "$STATUS_WARNING" == "1" ] ; then
    echo -n "WARNING"
    EXIT=1
  else
    echo -n "OK"
    EXIT=0
  fi
echo " - free space: "$OUTPUT"|"$PERFDATA
exit $EXIT
