#!/bin/sh
#--------
# Check PFsense interface script from CARP addess script for Icinga2
# Require: manubulon SNMP plugin 'check_snmp_int.pl', check_master.sh script from this repo
# v.20180406 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

 while getopts ":V:H:C:i:d:w:c:h" optname ; do
    case "$optname" in
#-V 2c -H 192.168.X.X -C communityro -i ovpns21 -d 300
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
      "i")
        INT=$OPTARG
        ;;
      "d")
        DELAY=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "w")
        WARN=$OPTARG
        ;;
      "h")
        echo "Useage: check_pfsense_interface.sh -H hostname -C community -i interface -w warn -c crit -d delay"
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
  [ -z $INT ] && echo "Please specify interface!" && exit 2
  [ -z $DELAY ] && DELAY=60
  [ -z $WARN ] && WARN="256000,256000"
  [ -z $CRIT ] && CRIT="512000,512000"

MASTER=`ssh -o ConnectTimeout=15 icinga2@$HOST ./check_master.sh`

  [ ! "$MASTER" ] && echo "Execution problem, probably hostname did not respond!" && exit 2

#/usr/lib64/nagios/plugins/check_snmp_int.pl --label 1 -$VERS -B -C $COMM -H $HOST -Y -c $CRIT -d $DELAY -f -k -n $INT -t 5 -w $WARN

MANUBULON="/usr/lib64/nagios/plugins/check_snmp_int.pl"

$MANUBULON -C $COMM -H $MASTER -$VERS -t 5 -w $WARN -c $CRIT -d $DELAY -n $INT -B -Y -f -k --label 1 -r
#	  case "$STATUS" in
#	    "OK")
#	      STATUS_OK=1
#	      ;;
#	    "WARNING")
#	      STATUS_WARNING=1
#	      ;;
#	    "CRITICAL")
#	      STATUS_CRITICAL=1
#	      ;;
#	    "NOK")
#	      STATUS_WARNING=1
#	      ;;
#	    *)
#	      CHECK=1
#	      ;;
#	  esac
#exit $EXIT
