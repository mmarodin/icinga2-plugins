# Check sql log shipping script for Icinga2
# Require: Powershell script execution enabled
# v.20190625 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

$USERNAME = "icinga2"
$PASSWORD = "readerlog"
#$QUERYLS = "SELECT * FROM [msdb].[dbo].[log_shipping_monitor_error_detail] WHERE [message] like '%Operating system error%'"
#$QUERYLS = "SELECT * FROM [msdb].[dbo].[log_shipping_monitor_error_detail] WHERE (CURRENT_TIMESTAMP - log_time) < 1"
$QUERYLS = "SELECT * FROM [msdb].[dbo].[log_shipping_monitor_error_detail] WHERE (datediff(minute, log_time, CURRENT_TIMESTAMP)) < 60"

#$LS = $(Invoke-Sqlcmd -Username $USERNAME -Password $PASSWORD -Query $QUERYLS).Name
$LS = $(Invoke-Sqlcmd -Username $USERNAME -Password $PASSWORD -Query $QUERYLS).message
#$LS

if ($LS) {
  Write-Host "CRITICAL - Log shipping problem:"
  Write-Host $LS
  $EXIT = 2
} else {
  Write-Host "OK - Log shipping is working"
  $EXIT = 0
}

$host.SetShouldExit($EXIT)