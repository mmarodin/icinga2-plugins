#!/bin/sh
#--------
# Check who is the pfSense master host script for Icinga2
# v.20180308 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":h" optname ; do
    case "$optname" in
      "h")
        echo "Useage: check_master.sh" 
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

#ifconfig lagg1_vlan100 | grep 192.168.X | grep -v vhid | awk '{print $2}'
##2.4.x changed interface names
ifconfig lagg1.100 | grep 192.168.X | grep -v vhid | awk '{print $2}'

exit 0
