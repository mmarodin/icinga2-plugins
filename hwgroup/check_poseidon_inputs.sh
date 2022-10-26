#!/bin/sh
#--------
# Check HWGroup Poseidon digital inputs/counters status script for Icinga2
# Require: net-snmp-utils, bc
# v.20220607 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:n:h" optname ; do
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
      "n")
        COUNT=1
        continue
        ;;
      "h")
        echo "Useage: check_poseidon_inputs.sh -H hostname -C community -V version [-n counters]"
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

#SNMPv2-SMI::enterprises.21796.3.3.1.1.2.1 = INTEGER: 0				Digital Input state
#SNMPv2-SMI::enterprises.21796.3.3.1.1.2.2 = INTEGER: 0
#SNMPv2-SMI::enterprises.21796.3.3.1.1.3.1 = STRING: "Fognatura Etra"		Digital Input name
#SNMPv2-SMI::enterprises.21796.3.3.1.1.3.2 = STRING: "Delta Fognatura Etra"A
#SNMPv2-SMI::enterprises.21796.3.3.1.1.5.1 = INTEGER: 0				Digital Input Alarm state
#SNMPv2-SMI::enterprises.21796.3.3.1.1.5.2 = INTEGER: 0
#SNMPv2-SMI::enterprises.21796.3.3.1.1.6.1 = INTEGER: 232			Digital Inputs counter
#SNMPv2-SMI::enterprises.21796.3.3.1.1.6.2 = INTEGER: 4

BASEOID="1.3.6.1.4.1.21796.3.3.1.1"

IFS=$IFS_NEWLINE
INPUTS_VALUE=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2 |  grep -v "No Such Object" | sed 's/.*INTEGER: \(.*\)/\1/g'`)
INPUTS_NAME=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.3 |  grep -v "No Such Object" | sed 's/.*\"\(.*\)\"/\1/g'`)
INPUTS_ALARMSTATE=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.5 |  grep -v "No Such Object" | sed 's/.*INTEGER: \(.*\)/\1/g'`)
INPUTS_COUNTER=(`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.6 |  grep -v "No Such Object" | sed 's/.*INTEGER: \(.*\)/\1/g'`)

  [ ! "$INPUTS_NAME" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$INPUTS_VALUE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$INPUTS_ALARMSTATE" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$INPUTS_COUNTER" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

  if [[ $COUNT -eq 1 ]] ; then

    TITLE="Digital Input Counters "
      for INDEX in "${!INPUTS_VALUE[@]}" ; do
        if [[ "${INPUTS_NAME[$INDEX]}" == *"Counter "* ]] ; then
          TEMP="${INPUTS_NAME[$INDEX]//Counter /}"
          TEXT="$TEXT - $TEMP ${INPUTS_COUNTER[$INDEX]}"
          LAST="$LAST ${TEMP// /_}=${INPUTS_COUNTER[$INDEX]}"
        fi
      done

  else

    TITLE="Digital Inputs "
      for INDEX in "${!INPUTS_VALUE[@]}" ; do
        if [[ "${INPUTS_NAME[$INDEX]}" != *"Binary "* && "${INPUTS_NAME[$INDEX]}" != *"Comm Monitor "* && "${INPUTS_NAME[$INDEX]}" != *"Counter "* ]] ; then
          TEXT="$TEXT - ${INPUTS_NAME[$INDEX]}"
          LAST="$LAST ${INPUTS_NAME[$INDEX]// /_}=${INPUTS_ALARMSTATE[$INDEX]}"
            if [[ ${INPUTS_ALARMSTATE[$INDEX]} -ne 0  ]] ; then
	      TEXT_CRIT="$TEXT_CRIT - ${INPUTS_NAME[$INDEX]}"
	      STATUS_CRITICAL=1
	      continue
            fi
        fi
      done

  fi

IFS=$IFS_CURRENT

echo -n "$TITLE"

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
