#!/bin/sh
#--------
# Check if secondary IP is configured or not
# script for Icinga2
# Require: ip
# v.20161223 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":i:h" optname ; do
    case "$optname" in
      "i")
        IP=$OPTARG
        ;;
      "h")
        echo "Useage: check_multi_ip.sh -i ipaddress"
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

  [ -z $IP ] && echo "Please specify IP address!" && exit 2

CHECK=`ip addr ls | grep $IP`

  if [ "$CHECK" ] ; then
    echo "OK - secondary IP $IP is up"
    EXIT=0
  else
    echo "CRITICAL - secondary IP $IP is down"
    EXIT=2
  fi

exit $EXIT