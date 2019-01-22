#!/bin/sh
#--------
# Check script for Docker Compose environment of GoHubble financial tool
# Run it as root user
# v.20180222 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

BASEFILE="/opt/scripts/icinga2/tmp/docker_status"
DEFAULT="$BASEFILE.default"
CURRENT="$BASEFILE.current"
NOW="$BASEFILE.`date +%Y%m%d%H%M`"

cd /etc/hubble
docker-compose ps > $CURRENT

CHECK=`diff -f $DEFAULT $CURRENT`
  if [ "$CHECK" ] ; then
    echo -e "CRITICAL - Docker problem, Compose diff:\n\n$CHECK"
    cp $CURRENT $NOW
    EXIT=2
  else
    echo "OK - Docker Compose is ok"
    EXIT=0
  fi

exit $EXIT
