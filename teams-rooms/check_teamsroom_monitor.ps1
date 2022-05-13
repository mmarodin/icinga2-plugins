# Check Teams Room monitor status script for Icinga2
# Require: Powershell script execution enabled
# v.20191129 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

$output = gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "Monitor"} | Format-Table Name,Status,Present
$test = gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "Monitor" -and $_.Status -ne "OK"}

If ($test) {
  $STATUS= "KO"
  $EXIT = 2
} Else {
  $STATUS= "OK"
  $EXIT = 0
}

Write-Host "Monitor: $STATUS"
$output
$host.SetShouldExit($EXIT)
