#!/bin/sh
#--------
# Check pfSense CARP status script for Icinga2
# v.20160409 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":s:h" optname ; do
    case "$optname" in
      "s")
        STATUS=$OPTARG
        ;;
      "h")
        echo "Useage: check_carp.sh -s status [master|backup]"
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

  [ -z $STATUS ] && echo "Please specify expected CARP status!" && exit 2
  [ "$STATUS" != "master" -a "$STATUS" != "backup" ] && echo "Please specify master or backup!" && exit 2

  for vhid in `ifconfig | grep MASTER | awk '{print $4}'`; do
      [ "$STATUS" == "backup" ] && LIST_MASTER="$LIST_MASTER `ifconfig | grep \"vhid $vhid \" | grep -v MASTER | awk '{print $2}'`"
    MASTER=1
  done

  for vhid in `ifconfig | grep BACKUP | awk '{print $4}'`; do
      [ "$STATUS" == "master" ] && LIST_BACKUP="$LIST_BACKUP `ifconfig | grep \"vhid $vhid \" | grep -v BACKUP | awk '{print $2}'`"
    BACKUP=1
  done

  [ "$STATUS" == "master" -a $BACKUP ] && echo "carp:CRITICAL - unexpected backup:$LIST_BACKUP" && exit 2
  [ "$STATUS" == "backup" -a $MASTER ] && echo "carp:CRITICAL - unexpected master:$LIST_MASTER" && exit 2

echo "carp:OK - all $STATUS"
exit 0
