#!/bin/sh
#--------
# Event command to restart a service (only if service.state_id is CRITICAL)
# script for Icinga2
# Require: systemd
# v.20170117 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":s:i:h" optname ; do
    case "$optname" in
      "s")
        SERVICE=$OPTARG
        ;;
      "i")
        STATEID=$OPTARG
        ;;
      "h")
        echo "Useage: event_restart_service.sh -s servicename -i servicestateid"
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

  [ -z $SERVICE ] && echo "Please specify service name!" && exit 2

  [ "$STATEID" == "2" ] && systemctl restart $SERVICE && exit 0

exit 3