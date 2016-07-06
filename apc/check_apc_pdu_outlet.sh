#!/bin/sh
#--------
# Check APC PDU outlet script for Icinga2
# Require: net-snmp-utils, bc
# v.20160411 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

 while getopts ":V:H:C:f:h" optname ; do
    case "$optname" in
      "V")
        VERSC=$OPTARG
	  if [ "$VERSC" = "2c" ] ; then
	    VERS="2"
	  else
	    VERS=$VERSC
	  fi
        ;;
      "H")
        HOST=$OPTARG
        ;;
      "C")
        COMM=$OPTARG
        ;;
      "f")
        FORM=$OPTARG
        ;;
      "h")
        echo "Useage: check_apc_pdu_outlet.sh -H hostname -C community -f format"
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

  [ -z $VERSC ] && VERSC="2c" && VERS="2"
  [ -z $HOST ] && echo "Please specify hostname!" && exit 2
  [ -z $COMM ] && echo "Please specify SNMP community!" && exit 2
  [ -z $FORM ] && FORM="html"

BANK1=0
BANK2=0
IFS_CURRENT=$IFS
IFS_COMMA=","
IFS_NEWLINE="
"
PDU_NAME=`snmpwalk -c $COMM -v $VERSC $HOST SNMPv2-MIB::sysName.0 | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 }'`

  [ ! "$PDU_NAME" ] && echo "No such PDU!" && exit 2

#OUTLET_NR=`snmpwalk -c $COMM -v $VERSC $HOST .1.3.6.1.4.1.318.1.1.12.3.5.1.1.1 | grep -v "No Such Instance" | wc -l`
#OUTLET_NR    .1.3.6.1.4.1.318.1.1.12.3.5.1.1.1
#OUTLET_NAME  .1.3.6.1.4.1.318.1.1.12.3.5.1.1.2
#OUTLET_STATE .1.3.6.1.4.1.318.1.1.12.3.5.1.1.4
#OUTLET_BANK  .1.3.6.1.4.1.318.1.1.12.3.5.1.1.6

BASEOID=".1.3.6.1.4.1.318.1.1.12.3.5.1.1"
OUTLET_NR=(0 $(snmpwalk -c $COMM -v $VERSC $HOST $BASEOID.1 | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 }'))
OUTLET_NAME=(0 $(snmpwalk -c $COMM -v $VERSC $HOST $BASEOID.2 | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 }' | sed 's/\"//g' | sed 's/ /_/g'))
OUTLET_STATE=(0 $(snmpwalk -c $COMM -v $VERSC $HOST $BASEOID.4 | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 }'))
OUTLET_BANK=(0 $(snmpwalk -c $COMM -v $VERSC $HOST $BASEOID.6 | grep -v "No Such Instance" | awk 'BEGIN { FS = ": " } { print $2 }'))

  [ "$FORM" == "txt" ] && OUTPUT="PDU $PDU_NAME outlet status:\n"

  for i in ${OUTLET_NR[@]} ; do
    [ "${OUTLET_STATE[i]}" == "2" -a "${OUTLET_NAME[i]}" != "Outlet_${OUTLET_NR[i]}" ] && CRITICAL="$CRITICAL #${OUTLET_NR[i]}"
    if [ "$FORM" == "txt" -a "$i" != "0" ] ; then
      OUTPUT=$OUTPUT"bank#${OUTLET_BANK[i]} - port#${OUTLET_NR[i]} - ${OUTLET_NAME[i]} - "
        if [ "${OUTLET_STATE[i]}" == "1" ] ; then
	  OUTPUT=$OUTPUT"on"
	else
	  OUTPUT=$OUTPUT"off"
	fi
      OUTPUT=$OUTPUT"\n"
    else
      if [ "${OUTLET_BANK[i]}" == "1" ] ; then
        BANK1=`echo "$BANK1 + 1" | bc -l`
        #PRE1="$PRE1<TD>port#$( [ ${OUTLET_NR[i]} -lt 10 ] && echo 0 )${OUTLET_NR[i]}</TD>"
        PRE1="$PRE1<TD>port#${OUTLET_NR[i]}</TD>"
	OUTPUT1="$OUTPUT1<TD"
          [ "${OUTLET_STATE[i]}" == "2" -a "${OUTLET_NAME[i]}" == "Outlet_${OUTLET_NR[i]}" ] && OUTPUT1="$OUTPUT1 CLASS=\"bg-color-warning\""
          [ "${OUTLET_STATE[i]}" == "2" -a "${OUTLET_NAME[i]}" != "Outlet_${OUTLET_NR[i]}" ] && OUTPUT1="$OUTPUT1 CLASS=\"bg-color-critical\""
	OUTPUT1="$OUTPUT1>${OUTLET_NAME[i]}</TD>"
      elif [ "${OUTLET_BANK[i]}" == "2" ] ; then
        BANK2=`echo "$BANK2 + 1" | bc -l`
        PRE2="$PRE2<TD>port#$( [ ${OUTLET_NR[i]} -lt 10 ] && echo 0 )${OUTLET_NR[i]}</TD>"
	OUTPUT2="$OUTPUT2<TD"
	  [ "${OUTLET_STATE[i]}" == "2" -a "${OUTLET_NAME[i]}" == "Outlet_${OUTLET_NR[i]}" ] && OUTPUT2="$OUTPUT2 CLASS=\"bg-color-warning\""
	  [ "${OUTLET_STATE[i]}" == "2" -a "${OUTLET_NAME[i]}" != "Outlet_${OUTLET_NR[i]}" ] && OUTPUT2="$OUTPUT2 CLASS=\"bg-color-critical\""
	OUTPUT2="$OUTPUT2>${OUTLET_NAME[i]}</TD>"
      fi
    fi
  done

  [ "$CRITICAL" != "" ] && echo -n "CRITICAL: ports $CRITICAL" && EXIT=2 || echo -n "OK: all configured outlet ports are on"
  [ "$FORM" == "txt" ] && echo -e "\n\n$OUTPUT"
  [ "$FORM" == "html" ] && echo "<BR><BR><TABLE CLASS=\"badge state-ok\"><TR><TD COLSPAN=\"$BANK1\">bank#1</TD></TR><TR>$PRE1</TR><TR>$OUTPUT1</TR></TABLE><BR><BR><TABLE CLASS=\"badge state-ok\"><TR><TD COLSPAN=\"$BANK2\">bank#2</TD></TR><TR>$PRE2</TR><TR>$OUTPUT2</TR></TABLE>"

exit $EXIT
