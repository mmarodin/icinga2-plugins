#!/bin/sh
#--------
# Check disk status script for Icinga2
# Require: Nagios 'check_disk' plugin
# Always return OK state
# v.20160413 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

PROGPATH=/usr/lib64/nagios/plugins

OUTPUT=`$PROGPATH/check_disk $@`
echo -n "DISK STATUS - "
echo $OUTPUT | awk 'BEGIN { FS = " - " } { print $2 }'
exit 0
