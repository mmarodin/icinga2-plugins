# Check single process script for Icinga2
# Require: Powershell script execution enabled
# v.20160421 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

param([string]$PROCESSNAME = "processname", [string]$WARNING = "warning", [string]$CRITICAL = "critical")

$PROCESS = Get-Process $PROCESSNAME -ErrorAction silentlycontinue
$COUNT = @($PROCESS).Count

  if (($COUNT -gt $CRITICAL) -or ($COUNT -eq 0)) {
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