#!/bin/sh
#--------
# Check Aruba Networks 5400Rzl2 load / memory / temperature / uptime / VSF stack status script for Icinga2
# Tested with K.16.02.x release
# Require: net-snmp-utils, bc
# v.20181016 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:w:c:m:h" optname ; do
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
      "m")
        MODE=$OPTARG
        ;;
      "h")
        echo "Useage: check_aruba_5400r_vsf_stack.sh -H hostname -C community -V version -w warn -c crit -m mode [ load | memory | temperature | uptime | vsf ]"
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
  [ -z $MODE ] && echo "Please specify mode!" && exit 2

WARN=(`echo $WARN`)
CRIT=(`echo $CRIT`)
IFS_CURRENT=$IFS
IFS_NEWLINE="
"
STACK_NAMES=(site1-sw5406r-01 site1-sw5406r-02 site2-sw5406r-01 site2-sw5406r-02)
STACK_SERIALS=(xxxxxxxxx1 xxxxxxxxx2 yyyyyyyyy1 yyyyyyyyy2)

function find_index {
  for INDEX in "${!STACK_SERIALS[@]}" ; do
    [[ "${STACK_SERIALS[$INDEX]}" == "$1" ]] && echo $INDEX && break
  done
}

#STACK SERIAL NUMBER
#hpicfVsfVCMIB.hpicfVsfVCObjects.hpicfVsfVCMemberTable.hpicfVsfVCMemberEntry.hpicfVsfVCMemberSerialNum
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.14.1	(string, "xxxxxxxxx1")
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.14.2	(string, "xxxxxxxxx2")

#STACK TEMPERATURE
#hpicfChassis.hpChassisTemperature.hpSystemAirTempTable.hpSystemAirTempEntry.hpSystemAirCurrentTemp
#SNMPv2-SMI::enterprises.11.2.14.11.1.2.8.1.1.3.0	(string, 22C)
#SNMPv2-SMI::enterprises.11.2.14.11.1.2.8.1.1.3.1	(string, 21C)

#STACK LOAD
#hpicfVsfVCMIB.hpicfVsfVCObjects.hpicfVsfVCMemberTable.hpicfVsfVCMemberEntry.hpicfVsfVCMemberCpuUtil
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.19.1	(integer, 32)
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.19.2	(integer, 15)

#STACK TOTAL MEMORY
#hpicfVsfVCMIB.hpicfVsfVCObjects.hpicfVsfVCMemberTable.hpicfVsfVCMemberEntry.hpicfVsfVCMemberTotalMemory
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.20.1	(integer, 692510720)
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.20.2	(integer, 692510720)

#STACK FREE MEMORY
#hpicfVsfVCMIB.hpicfVsfVCObjects.hpicfVsfVCMemberTable.hpicfVsfVCMemberEntry.hpicfVsfVCMemberFreeMemory
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.21.1	(integer, 499512880)
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.21.2	(integer, 518238264)

#VSF LINK STATUS
#hpicfVsfVCMIB.hpicfVsfVCObjects.hpicfVsfVCPortTable.hpicfVsfVCPortEntry.hpicfVsfVCPortOperStatus
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.5.1.1.33	(integer, 1)
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.5.1.1.85	(integer, 1)
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.5.1.1.225	(integer, 1)
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.5.1.1.277	(integer, 1)

#VSF LINK DETAIL
#hpicfVsfVCMIB.hpicfVsfVCObjects.hpicfVsfVCPortTable.hpicfVsfVCPortEntry.hpicfVsfVCPortOperStatusErrorStr
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.5.1.2.33	(string, "Connected to port 2/B1")
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.5.1.2.85	(string, "Connected to port 2/C21")
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.5.1.2.225	(string, "Connected to port 1/B1")
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.5.1.2.277	(string, "Connected to port 1/C21")

#STACK INTERFACE DESCRIPTION
#ifTable.ifEntry.ifDescr
#IF-MIB::ifDescr.33					(string, 1/B1)
#IF-MIB::ifDescr.85					(string, 1/C21)
#IF-MIB::ifDescr.225					(string, 2/B1)
#IF-MIB::ifDescr.277					(string, 2/C21)

#STACK UPTIME
#hpicfVsfVCMIB.hpicfVsfVCObjects.hpicfVsfVCMemberTable.hpicfVsfVCMemberEntry.hpicfVsfVCMemberUpTime
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.11.1	(timeticks, "(647605200) 74 days, 22:54:12.00")
#SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.11.2	(timeticks, "(647555100) 74 days, 22:45:51.00")

STACK_SERIAL=(`snmpwalk -v$VERS -c $COMM $HOST SNMPv2-SMI::enterprises.11.2.14.11.5.1.116.1.3.1.14 | grep -v "No Such Object" | sed 's/.*\"\(.*\)\"/\1/g'`)
  [ ! "$STACK_SERIAL" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  case "$MODE" in

    "temperature")
        #[ -z $WARN ] && WARN="45 45"
        #[ -z $CRIT ] && CRIT="55 55"
      TEMPERATURE_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.11.2.14.11.1.2.8.1.1.3 | grep -v "No Such Object" | sed 's/.*\"\(.*\)C\"/\1/g'`)

      IFS=$IFS_NEWLINE
      [ ! "$TEMPERATURE_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

	for INDEX in "${!TEMPERATURE_VALUE[@]}" ; do
	  TEXT="$TEXT - ${STACK_NAMES[`find_index "${STACK_SERIAL[$INDEX]}"`]} ${TEMPERATURE_VALUE[$INDEX]}C"
	  TEMPERATURE_ROUND=`echo "scale=0; ${TEMPERATURE_VALUE[$INDEX]}" / 1 | bc`
      
	  LAST="$LAST ${STACK_NAMES[`find_index "${STACK_SERIAL[$INDEX]}"`]}=${TEMPERATURE_VALUE[$INDEX]};${WARN[$INDEX]};${CRIT[$INDEX]}"
	    if [ $TEMPERATURE_ROUND -ge ${CRIT[$INDEX]} ] ; then
	      STATUS_CRITICAL=1
	    fi
	    if [ $TEMPERATURE_ROUND -ge ${WARN[$INDEX]} ] ; then
	      STATUS_WARNING=1
	    fi
	done

      PRE="Temperature"
      ;;

    "load")
        #[ -z $WARN ] && WARN="85 85"
        #[ -z $CRIT ] && CRIT="95 95"
      LOAD_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.19 | grep -v "No Such Object" | sed 's/.*\INTEGER: \(.*\)/\1/g'`)

      IFS=$IFS_NEWLINE
      [ ! "$LOAD_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

	for INDEX in "${!LOAD_VALUE[@]}" ; do
	  TEXT="$TEXT - ${STACK_NAMES[`find_index "${STACK_SERIAL[$INDEX]}"`]} ${LOAD_VALUE[$INDEX]}%"
      
	  LAST="$LAST ${STACK_NAMES[`find_index "${STACK_SERIAL[$INDEX]}"`]}=${LOAD_VALUE[$INDEX]}%;${WARN[$INDEX]};${CRIT[$INDEX]}"
	    if [ ${LOAD_VALUE[$INDEX]} -ge ${CRIT[$INDEX]} ] ; then
	      STATUS_CRITICAL=1
	    fi
	    if [ ${LOAD_VALUE[$INDEX]} -ge ${WARN[$INDEX]} ] ; then
	      STATUS_WARNING=1
	    fi
	done

      PRE="Load"
      ;;

    "memory")
        #[ -z $WARN ] && WARN="85 85"
        #[ -z $CRIT ] && CRIT="95 95"
      TOTALMEMORY_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.20 | grep -v "No Such Object" | sed 's/.*\INTEGER: \(.*\)/\1/g'`)
      FREEMEMORY_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.21 | grep -v "No Such Object" | sed 's/.*\INTEGER: \(.*\)/\1/g'`)

      IFS=$IFS_NEWLINE
      [ ! "$TOTALMEMORY_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
      [ ! "$FREEMEMORY_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

	for INDEX in "${!TOTALMEMORY_VALUE[@]}" ; do
	  MEM_CRIT=`echo "scale=0;$(expr ${TOTALMEMORY_VALUE[$INDEX]} / 100) * ${CRIT[$INDEX]}" | bc`
	  MEM_WARN=`echo "scale=0;$(expr ${TOTALMEMORY_VALUE[$INDEX]} / 100) * ${WARN[$INDEX]}" | bc`
	  MEM_USED=`echo "$(expr ${TOTALMEMORY_VALUE[$INDEX]} - ${FREEMEMORY_VALUE[$INDEX]})" | bc`
	  USAGE=`echo "scale=2 ; $MEM_USED / ${TOTALMEMORY_VALUE[$INDEX]} * 100" | bc`
	  TEXT="$TEXT - ${STACK_NAMES[`find_index "${STACK_SERIAL[$INDEX]}"`]} "$USAGE"%"
      
	  LAST="$LAST ${STACK_NAMES[`find_index "${STACK_SERIAL[$INDEX]}"`]}=$MEM_USED;$MEM_WARN;$MEM_CRIT;0;${TOTALMEMORY_VALUE[$INDEX]}"
	    if [ $MEM_USED -ge $MEM_CRIT ] ; then
	      STATUS_CRITICAL=1
	    fi
	    if [ $MEM_USED -ge $MEM_WARN ] ; then
	      STATUS_WARNING=1
	    fi
	done

      PRE="Memory"
      ;;

    "vsf")
      VSF_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.11.2.14.11.5.1.116.1.5.1.1 | grep -v "No Such Instance" | sed 's/.*116.1.5.1.1\(.*\)/\1/g' | sed 's/^\(.*\) = INTEGER: \(.*\)/\1,\2/g' | sed 's/"//g'`)
      LINKDETAIL_BASEOID=".1.3.6.1.4.1.11.2.14.11.5.1.116.1.5.1.2"
      IFDESCR_BASEOID=".1.3.6.1.2.1.2.2.1.2"

      IFS=$IFS_NEWLINE
      [ ! "$VSF_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

      PORTOK=0
      PORTKO=0
	for INDEX in "${!VSF_VALUE[@]}" ; do
	  IFINDEX=`echo ${VSF_VALUE[$INDEX]} | awk 'BEGIN { FS = "," } { print $1 }'`
	  VFSSTATUS=`echo ${VSF_VALUE[$INDEX]} | awk 'BEGIN { FS = "," } { print $2 }'`
	    if [ "$VFSSTATUS" == "1" ] ; then
	      TEXT="$TEXT - `snmpwalk -v$VERS -c $COMM $HOST $IFDESCR_BASEOID$IFINDEX | grep -v "No Such Object" | sed 's/.*STRING: \(.*\)/\1/g'`: `snmpwalk -v$VERS -c $COMM $HOST $LINKDETAIL_BASEOID$IFINDEX | grep -v "No Such Object" | sed 's/.*\"\(.*\)\"/\1/g'`"
	      ((PORTOK++))
	    else
	      TEXT_CRIT="$TEXT_CRIT - `snmpwalk -v$VERS -c $COMM $HOST $IFDESCR_BASEOID$IFINDEX | grep -v "No Such Object" | sed 's/.*STRING: \(.*\)/\1/g'`: disconnected"
	      ((PORTKO++))
	    fi
	done

        [ $PORTOK -eq 0 ] && STATUS_CRITICAL=1
        [ $PORTKO -ne 0 ] && STATUS_WARNING=1

      PRE="VSF"
      LAST=" 'port_ok'=$PORTOK 'port_ko'=$PORTKO"
      ;;

    "uptime")
        #[ -z $CRIT ] && CRIT="86400 86400"
      IFS=$IFS_NEWLINE
      UPTIME_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST .1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.11 | grep -v "No Such Object" | sed 's/.* = \(.*\)/\1/g'`)

      [ ! "$UPTIME_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

	for INDEX in "${!UPTIME_VALUE[@]}" ; do
	  TIMETICKS=`echo ${UPTIME_VALUE[$INDEX]} | sed 's/.*(\(.*\)).*/\1/'`
	  SECONDS=`echo "scale=0; $TIMETICKS / 100" | bc`
	  TEXT="$TEXT - ${STACK_NAMES[`find_index "${STACK_SERIAL[$INDEX]}"`]} ${UPTIME_VALUE[$INDEX]}"
      
	  LAST="$LAST ${STACK_NAMES[`find_index "${STACK_SERIAL[$INDEX]}"`]}="$SECONDS"s;0;${CRIT[$INDEX]}"
	    if [ $SECONDS -lt ${CRIT[$INDEX]} ] ; then
	      STATUS_CRITICAL=1
	    fi
	done

      PRE="Uptime"
      ;;

    *)
    # Should not occur
      echo "Unknown error while processing mode"
      exit 1
      ;;
  esac

IFS=$IFS_CURRENT

echo -n "$PRE "

  if [ $STATUS_CRITICAL ] ; then
    echo -n "CRITICAL"
    EXIT=2
  elif [ $STATUS_WARNING ] ; then
    echo -n "WARNING"
    EXIT=1
  else
    echo -n "OK"
    EXIT=0
  fi

  [ "$TEXT_CRIT" != "" ] && echo -n "$TEXT_CRIT" || echo -n "$TEXT"
echo -e " |$LAST"
exit $EXIT
