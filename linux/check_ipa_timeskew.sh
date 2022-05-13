#!/bin/sh
#--------
# Check IPA Replica time skew script for Icinga2
# v.20210428 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

IFS_CURRENT=$IFS
IFS_NEWLINE="
"
MAXDAYS=10

IFS=$IFS_NEWLINE
#CNS=( $(/opt/scripts/readNsState.py /etc/dirsrv/slapd-IPA-MYDOMAIN-COM/dse.ldif | grep 'For replica' | sed 's/For replica \(.*\)/\1/g' | sed -r 's/\\3D/=/g' | sed -r 's/\\2D/,/g') )
CNS=( $(/opt/scripts/readNsState.py /etc/dirsrv/slapd-IPA-MYDOMAIN-COM/dse.ldif | grep 'For replica' | sed 's/For replica cn=\(.*\),cn=mapping tree.*/\1/g' | sed -r 's/,cn=dc//g' | sed -r 's/,cn=o//g' | sed -r 's/dc//g' | sed -r 's/\\3D/_/g' | sed -r 's/\\2C//g') )
DAYS=( $(/opt/scripts/readNsState.py /etc/dirsrv/slapd-IPA-MYDOMAIN-COM/dse.ldif | grep 'Day:sec diff' | sed 's/    Day:sec diff  : \(.*\):.*/\1/g') )

  for INDEX in "${!CNS[@]}" ; do
      if [ ${DAYS[$INDEX]} -gt $MAXDAYS ] || [ ${DAYS[$INDEX]} -lt -$MAXDAYS ] ; then
	TEXT_CRIT="$TEXT_CRIT - Replica for CN ${CNS[$INDEX]}: Days diff ${DAYS[$INDEX]}"
	STATUS_CRITICAL=1
      fi
    LAST="$LAST ${CNS[$INDEX]}=${DAYS[$INDEX]}"
  done

IFS=$IFS_CURRENT

echo -n "IPA Replica time skew are "
  if [ $STATUS_CRITICAL ] ; then
    echo -n "CRITICAL"
    EXIT=2
  else
    echo -n "OK"
    EXIT=0
  fi

  [ "$TEXT_CRIT" != "" ] && echo -n "$TEXT_CRIT"

echo -e " |$LAST"
exit $EXIT
