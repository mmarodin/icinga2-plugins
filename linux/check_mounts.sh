#!/bin/sh
#--------
# Check if all external mounts exists and if they are correct implemented,
# script for Icinga2
# Written for cifs, davfs and nfs mounts
# Require: bc, comm
# v.20180709 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

TMP_MOUNT=/tmp/tmp_icinga2_disk.mount
TMP_FSTAB=/tmp/tmp_icinga2_disk.fstab
PLUGIN=/usr/lib64/nagios/plugins/check_disk
IFS_ORIG=$IFS
IFS_NL='
'

IFS=$IFS_NL
  for MOUNT in `cat /proc/mounts` ; do
    TYPE=`echo $MOUNT | awk '{ print $3 }'`
      case $TYPE in
	cifs|davfs|nfs)
	    [ "$MOUNT_PART" ] && MOUNT_PART=$MOUNT_PART"\n"
	  MOUNT_PART=$MOUNT_PART"`echo $MOUNT | awk '{ print $2 }'`"
	  ;;
	*)
	  ;;
      esac
  done
  for FSTAB in `cat /etc/fstab` ; do
    if [ ${FSTAB:0:1} != \# ] ; then
      TYPE=`echo $FSTAB | awk '{ print $3 }'`
	case $TYPE in
	  cifs|davfs|nfs)
	      [ "$FSTAB_PART" ] && FSTAB_PART=$FSTAB_PART"\n"
	    FSTAB_PART=$FSTAB_PART"`echo $FSTAB | awk '{ print $2 }'`"
	    ;;
	  *)
	    ;;
        esac
    fi
  done
IFS=$IFS_ORIG

echo -e $MOUNT_PART | sort > $TMP_MOUNT
echo -e $FSTAB_PART | sort > $TMP_FSTAB

CHECK_CRITICAL=`/usr/bin/comm -13 $TMP_MOUNT $TMP_FSTAB`
CHECK_WARNING=`/usr/bin/comm -13 $TMP_FSTAB $TMP_MOUNT`

OUTPUT=`$PLUGIN -N cifs -N davfs -N nfs -w 20% -c 10%`
PERFDATA=`echo $OUTPUT | awk 'BEGIN { FS = "|" } { print $2 }'`

  if [ "$CHECK_CRITICAL" ] ; then
    COUNT=0
    echo -n "CRITICAL: "
      for UNMOUNT in `echo $CHECK_CRITICAL` ; do
	  [ "$COUNT" != "0" ] && echo -n " "
	echo -n "$UNMOUNT"
	COUNT=`echo "$COUNT + 1" | bc -l`
      done
    echo -n " "
      [ "$COUNT" -eq "1" ] && echo -n "is" || echo -n "are"
    echo -n "n't mounted"
    EXIT=2
  elif [ "$CHECK_WARNING" ] ; then
    COUNT=0
    echo -n "WARNING: "
      for UNEXPECTED in `echo $CHECK_WARNING` ; do
	  [ "$COUNT" != "0" ] && echo -n " "
	echo -n "$UNEXPECTED"
	COUNT=`echo "$COUNT + 1" | bc -l`
      done
    echo -n " "
      [ "$COUNT" -eq "1" ] && echo -n "is" || echo -n "are"
    echo -n " mounted but not in fstab"
    EXIT=1
  else
      [ "$MOUNT_PART" == "" -a "$FSTAB_PART" == "" ] && echo "OK: no mountpoints defined" && exit 0
    COUNT=0
    echo -n "OK: all mounts were found ("
      for MOUNT in `cat $TMP_MOUNT` ; do
	  [ "$COUNT" != "0" ] && echo -n " "
	echo -n "$MOUNT"
	COUNT=`echo "$COUNT + 1" | bc -l`
      done
    echo -n ")"
    EXIT=0
  fi
echo " |"$PERFDATA
exit $EXIT
