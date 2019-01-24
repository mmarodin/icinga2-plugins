#!/bin/sh
#--------
# Check Ricoh toner status script for Icinga2
# Require: net-snmp-utils, grep, sed
# v.20181214 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:w:c:h" optname ; do
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
        echo "Useage: check_ricoh_toner.sh -H hostname -C community -V version -w warn -c crit"
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
  [ -z $WARN ] && WARN=30
  [ -z $CRIT ] && CRIT=15

#.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.1	Black		(integer, NUM (0..100))
#.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.2	Cyan		(integer, NUM (0..100))
#.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.3	Magenta		(integer, NUM (0..100))
#.1.3.6.1.4.1.367.3.2.1.2.24.1.1.5.4	Yellow		(integer, NUM (0..100))
#.1.3.6.1.4.1.367.3.2.1.6.1.1.7.1	Name		(string, VALUE)
#.1.3.6.1.4.1.367.3.2.1.6.1.1.8.1	Position	(string, VALUE)

BASEOID="1.3.6.1.4.1.367.3.2.1"

BLACK=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.24.1.1.5.1 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
CYAN=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.24.1.1.5.2 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
MAGENTA=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.24.1.1.5.3 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
YELLOW=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.2.24.1.1.5.4 | grep -v "No Such Instance" | sed 's/.*INTEGER: \(.*\)/\1/g'`
NAME=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.6.1.1.7.1 | grep -v "No Such Instance" | sed 's/.*\"\(.*\)\"/\1/g'`
POSITION=`snmpwalk -v$VERS -c $COMM $HOST $BASEOID.6.1.1.8.1 | grep -v "No Such Instance" | sed 's/.*\"\(.*\)\"/\1/g'`

  [ ! "$BLACK" ] && echo "Execution problem, probably hostname did not respond!" && exit 2
  [ ! "$POSITION" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

TEXT="$NAME ($POSITION) - Black $BLACK"
LAST="'black'=$BLACK;$WARN;$CRIT;0;100"

  if [ $BLACK -lt $WARN ]; then
    STATUS_WARNING=1
  fi
  if [ $BLACK -lt $CRIT ]; then
    STATUS_CRITICAL=1
  fi

  if [[ $MAGENTA && $CYAN && $YELLOW ]]; then
    TEXT="$TEXT, Cyan $CYAN, Magenta $MAGENTA, Yellow $YELLOW"
    LAST="$LAST 'cyan'=$CYAN;$WARN;$CRIT;0;100 'magenta'=$MAGENTA;$WARN;$CRIT;0;100 'yellow'=$YELLOW;$WARN;$CRIT;0;100"

    if [ $CYAN -lt $WARN ]; then
      STATUS_WARNING=1
    fi
    if [ $CYAN -lt $CRIT ]; then
      STATUS_CRITICAL=1
    fi

    if [ $MAGENTA -lt $WARN ]; then
      STATUS_WARNING=1
    fi
    if [ $MAGENTA -lt $CRIT ]; then
      STATUS_CRITICAL=1
    fi

    if [ $YELLOW -lt $WARN ]; then
      STATUS_WARNING=1
    fi
    if [ $YELLOW -lt $CRIT ]; then
      STATUS_CRITICAL=1
    fi
  fi

echo -n "Toner "

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

echo -n " - $TEXT"
echo -e " | $LAST"
exit $EXIT
