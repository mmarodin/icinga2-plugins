#!/bin/sh
#--------
# Check local uptime (perfdata in seconds) script for Icinga2
# Require: bc, RHEL 7.x compatible systems
# v.20160420 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:c:h" optname ; do
    case "$optname" in
      "V")
        VERS=$OPTARG
        ;;
      "c")
        CRIT=$OPTARG
        ;;
      "h")
        echo "Useage: check_uptime_local.sh -c crit"
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

  [ -z $CRIT ] && CRIT=86400

SECONDS=`cat /proc/uptime | awk 'BEGIN { FS = "." } { print $1 }'`
OUTPUT=`uptime -p`

  [ ! "$SECONDS" ] && echo "Execution problem, something went wrong!" && exit 2

echo -n "Uptime "

  [ $SECONDS -lt $CRIT ] && EXIT=2 && echo -n "CRITICAL" || echo -n "OK"

echo " - "$OUTPUT" | 'uptime'="$SECONDS"s;;;"
exit $EXIT
