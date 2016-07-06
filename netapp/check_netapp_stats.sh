#!/bin/sh
#--------
# Check Netapp (cDOT mode) ops/throughput/latency script for Icinga2
# Require: net-snmp-utils, bc, expect 'check_netapp_stats.exp' script
# v.20160617 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

 while getopts ":V:H:u:p:h" optname ; do
    case "$optname" in
      "V")
        VSRV=$OPTARG
        ;;
      "H")
        HOST=$OPTARG
        ;;
      "u")
        USER=$OPTARG
        ;;
      "p")
        PASS=$OPTARG
        ;;
      "h")
        echo "Useage: check_netapp_stats.sh -H hostname -u user -p password -V vserver"
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

  [ -z $HOST ] && echo "Please specify hostname!" && exit 2
  [ -z $USER ] && echo "Please specify username!" && exit 2
  [ -z $PASS ] && echo "Please specify password!" && exit 2
  [ -z $VSRV ] && echo "Please specify vserver!" && exit 2

EXSCRIPT="/opt/scripts/icinga2/check_netapp_stats.exp"
FILE="/tmp/tmp_icinga2_stats.$HOST.$VSRV"

#$EXSCRIPT $HOST $USER $PASS >/dev/null 2>&1
$EXSCRIPT $HOST $USER $PASS $VSRV >/dev/null 2>&1

  [ ! -e $FILE ] && echo "Execution problem, probably hostname did not respond!" && exit 2

VALUES=(`cat $FILE | grep "$VSRV "`)

  [ ${#VALUES[@]} -lt 7 ] && echo "Netapp CLI problem!" && exit 2
  [ "${VALUES[7]}" == "-" ] && VALUES[7]=0

echo "OK: ${VALUES[0]} - Total Ops : ${VALUES[1]}, Read Ops : ${VALUES[2]}, Write Ops : ${VALUES[3]}, Other Ops : ${VALUES[4]}, Read : ${VALUES[5]} Bps, Write : ${VALUES[6]} Bps, Latency : ${VALUES[7]} us | 'ops_total'=${VALUES[1]};0;0;0 'ops_read'=${VALUES[2]};0;0;0 'ops_write'=${VALUES[3]};0;0;0 'ops_other'=${VALUES[4]};0;0;0 'read'=${VALUES[5]}B;0;0;0 'write'=${VALUES[6]}B;0;0;0 'latency'=${VALUES[7]}us;0;0;0"

exit 0
