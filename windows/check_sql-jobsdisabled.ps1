# Check sql jobs disabled script for Icinga2
# Require: Powershell script execution enabled
# v.20161222 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

$USERNAME = "icinga2"
$PASSWORD = "********"
$QUERYLS = "SELECT name, enabled FROM [msdb].[dbo].[sysjobs] WHERE [enabled]=0"

$JE = $(Invoke-Sqlcmd -Username $USERNAME -Password $PASSWORD -Query $QUERYLS).Name
#$JE

if ($JE) {
  Write-Host "CRITICAL - Some jobs is disabled"
  Write-Host "$JE"
  $EXIT = 2
} else {
  Write-Host "OK - Jobs are all enabled"
  $EXIT = 0
}

$host.SetShouldExit($EXIT)