# Check single process script for Icinga2
# Require: Powershell script execution enabled
# v.20161102 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

param([string]$PROCESSNAME = "processname", [string]$WARNING = "warning", [string]$CRITICAL = "critical")

$PROCESS = Get-Process $PROCESSNAME -ErrorAction silentlycontinue

  if (! $PROCESS) {
    $COUNT = 0
  } else {
    $COUNT = @($PROCESS).Count
  }

  if (($COUNT -gt $CRITICAL) -or (! $PROCESS)) {
    $STATUS = "CRITICAL"
    $EXIT = 2
  }
  elseif ($COUNT -gt $WARNING) {
    $STATUS = "WARNING"
    $EXIT = 1
  }
  else {
    $STATUS = "OK"
    $EXIT = 0
  }

Write-Host "PROCS "$STATUS" : "$COUNT" processes with command name '"$PROCESSNAME"' | 'procs'="$COUNT";"$WARNING";"$CRITICAL
$host.SetShouldExit($EXIT)