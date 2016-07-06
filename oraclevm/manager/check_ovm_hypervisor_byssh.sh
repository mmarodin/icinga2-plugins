#!/bin/sh
#--------
# Check Oracle VM Hypervisor script for Icinga2
# v.20160509 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":V:H:C:p:h" optname ; do
    case "$optname" in
      "V")
        VERS=$OPTARG
        ;;
      "H")
        HYPVM=$OPTARG
        ;;
      "C")
        CHECK=$OPTARG
        ;;
      "p")
        PARAM=$OPTARG
        ;;
      "h")
        echo "Useage: check_ovm_hypervisor_byssh.sh -H hostname -C checkname [-p parameters]"
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

  [ -z $HYPVM ] && echo "Missing hostname" && exit 2
  [ -z $CHECK ] && echo "Missing checkname" && exit 2
  [ "`echo $PARAM | grep ";"`" ] && echo "No hacking, please!" && exit 2
  [ "`echo $PARAM | grep "|"`" ] && echo "No hacking, please!" && exit 2

  [ "$PARAM" ] && PARAM=`echo $PARAM | sed "s/'//g"`

  case $CHECK in
    check_disk | check_disk_status.sh | check_load | check_mem.pl | check_ntp_time | check_procs | check_swap | check_traffic.sh | check_uptime_local.sh | check_users | check_ovm_runningvm.sh | check_linux_bonding | check_ovm_mem.sh)
      ssh $HYPVM /opt/scripts/icinga2/$CHECK $PARAM
      ;;
    *)
      echo "Invalid checkname!"
      exit 1
      ;;
  esac
