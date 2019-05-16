#!/bin/sh
#--------
# Check Aruba Networks interface error status script for Icinga2
# Tested with K.16.02.x release
# Require: net-snmp-utils, bc
# v.20181015 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:p:h" optname ; do
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
      "p")
        PORT=$OPTARG
        ;;
      "h")
        echo "Useage: check_aruba_iferrors.sh -H hostname -C community -V version -p port"
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
  [ -z $PORT ] && echo "Please specify interface!" && exit 2

#IF-MIB::ifName.102					(string: E6)
IFNAME=`snmpwalk -v $VERS -c $COMM $HOST IF-MIB::ifName | grep "$PORT" | grep -v "No Such Object" | sed "s/IF-MIB::ifName.\(.*\) = STRING: $PORT/\1/g"`

#IF-MIB::ifInDiscards.102		(counter32: 328142)
#IF-MIB::ifInErrors.102			(counter32: 0)
#IF-MIB::ifOutDiscards.102	(counter32: 128580936)
#IF-MIB::ifOutErrors.102		(counter32: 0)
IFINDISC=`snmpwalk -v $VERS -c $COMM $HOST IF-MIB::ifInDiscards.$IFNAME | grep -v "No Such Object" | sed "s/.*\.$IFNAME = Counter32: \(.*\)/\1/g"`
IFINERR=`snmpwalk -v $VERS -c $COMM $HOST IF-MIB::ifInErrors.$IFNAME | grep -v "No Such Object" | sed "s/.*\.$IFNAME = Counter32: \(.*\)/\1/g"`
IFOUTDISC=`snmpwalk -v $VERS -c $COMM $HOST IF-MIB::ifOutDiscards.$IFNAME | grep -v "No Such Object" | sed "s/.*\.$IFNAME = Counter32: \(.*\)/\1/g"`
IFOUTERR=`snmpwalk -v $VERS -c $COMM $HOST IF-MIB::ifOutErrors.$IFNAME | grep -v "No Such Object" | sed "s/.*\.$IFNAME = Counter32: \(.*\)/\1/g"`

echo -n "Interface $PORT: $IFNAME"
echo " | 'ifindiscards'="$IFINDISC"c 'ifinerrors'="$IFINERR"c 'ifoutdiscards'="$IFOUTDISC"c 'ifouterrors'="$IFOUTERR"c"