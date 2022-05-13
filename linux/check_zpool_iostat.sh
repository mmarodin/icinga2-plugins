#!/bin/sh
#--------
# Check zfs pool iostat for Icinga2
# v.20220407 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

  while getopts ":p:h" optname ; do
    case "$optname" in
      "p")
        POOL=$OPTARG
        ;;
      "h")
        echo "Useage: check_zpool_iostat -p poolname"
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

  [ -z $POOL ] && POOL="data"

OUTPUT=`zpool iostat -H -y -p $POOL 5 1`
#echo $OUTPUT

  if [ "$?" -eq 1 ] ; then
    exit 2
  fi

OPS_READ=`echo $OUTPUT | awk '{ print $4 }'`
OPS_WRITE=`echo $OUTPUT | awk '{ print $5 }'`
BAN_READ=`echo $OUTPUT | awk '{ print $6 }'`
BAN_WRITE=`echo $OUTPUT | awk '{ print $7 }'`
echo "IOstat $POOL pool - OPS read $OPS_READ, OPS write $OPS_WRITE, bandwidth read $BAN_READ, bandwidth write $BAN_WRITE | ops_read=$OPS_READ ops_write=$OPS_WRITE bandwidth_read=$BAN_READ bandwidth_write=$BAN_WRITE"

exit 0
