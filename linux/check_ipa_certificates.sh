#!/bin/sh
#--------
# Check IPA Certificates status script for Icinga2
# v.20210322 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

TODAY=`date +%Y-%m-%d`
STATUS="MONITORING"
CRIT=30
IFS_CURRENT=$IFS
IFS_NEWLINE="
"

IFS=$IFS_NEWLINE
STATS=( $(getcert list | grep 'status:' | sed 's/.*status: \(.*\)/\1/g') )
SUBJS=( $(getcert list | grep 'subject:' | sed 's/.*subject: \(.*\)/\1/g') )
EXPS=( $(getcert list | grep 'expires:' | sed 's/.*expires: \(.*\) .* UTC/\1/g') )

  for INDEX in "${!STATS[@]}" ; do
    DIFF=$(( ($(date -d "${EXPS[$INDEX]}" +%s) - $(date -d "$TODAY" +%s)) / (60*60*24) ))
      if [ "${STATS[$INDEX]}" != "$STATUS" ] ; then
	TEXT_CRIT="$TEXT_CRIT - ${SUBJS[$INDEX]}: ${STATS[$INDEX]}"
	STATUS_CRITICAL=1
      fi
      if [[ $DIFF -le $CRIT ]] ; then
        TEXT_CRIT="$TEXT_CRIT - ${SUBJS[$INDEX]}: expires in $DIFF days"
        STATUS_CRITICAL=1
      fi
  done

IFS=$IFS_CURRENT

echo -n "IPA Certificates "
  if [ $STATUS_CRITICAL ] ; then
    echo -n "CRITICAL"
    EXIT=2
  else
    echo -e "OK"
    EXIT=0
  fi

  [ "$TEXT_CRIT" != "" ] && echo -e "$TEXT_CRIT"
exit $EXIT
