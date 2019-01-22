#!/bin/bash
#----------
# Check if PacketFence services are running or not
# Tested with PacketFence 7.4.x release
# v.20180404 by mmarodin
#
FILE=/tmp/tmp_icinga2_packetfence.status

/usr/local/pf/bin/pfcmd service pf status > $FILE

  for SERVICE in `cat $FILE | grep -v shouldBeStarted | grep -v httpd.collector | grep -v httpd.proxy | grep -v pfbandwidthd | grep -v pfdetect | grep -v pfsetvlan | grep -v redis_ntlm_cache | grep -v routes | grep -v snmptrapd` ; do
    NAME=`echo $SERVICE | awk 'BEGIN { FS = "|" } { print $1 }'`
    STATUS=`echo $SERVICE | awk 'BEGIN { FS = "|" } { print $2 }'`
    PID=`echo $SERVICE | awk 'BEGIN { FS = "|" } { print $3 }'`
    #echo "$NAME - $STATUS"
      if [ "$STATUS" -ne "1" ] || [ "$PID" -eq "0" ] ; then
	CHECK=1
	PERFDATA=$PERFDATA$NAME" "
      fi
  done

  if [ "$CHECK" == "1" ] ; then
    echo "Problem - PacketFence services stopped: $PERFDATA"
    EXIT=2
  else
    echo "OK - All PacketFence services are running"
    EXIT=0
  fi

exit $EXIT
