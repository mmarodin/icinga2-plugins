#!/bin/sh
#--------
# Check running VMs script for Icinga2
# Customized for Oracle VM server 3.2
# v.20160509 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":w:c:h" optname ; do
    case "$optname" in
      "w")
        WARN=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "h")
        echo "Useage: check_check_ovm_runningvm.sh -w warning -c critical"
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

  [ -z $WARN ] && WARN=20
  [ -z $CRIT ] && CRIT=30

VMS=`xm list | grep -v Name | grep -v Domain-0 | wc -l`

  if [ $VMS -gt $CRIT ] ; then
    echo -n "CRITICAL"
    EXIT=2
  elif [ $VMS -gt $WARN ] ; then
    echo -n "WARNING"
    EXIT=1
  else
    echo -n "OK"
    EXIT=0
  fi

echo ": $VMS running VMs | 'vms'=$VMS;$WARN;$CRIT;"
exit $EXIT
