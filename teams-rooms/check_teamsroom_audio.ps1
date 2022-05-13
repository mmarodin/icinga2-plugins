# Check Teams Room audio status script for Icinga2
# Require: Powershell script execution enabled
# v.20191129 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

$output = gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "Media"} | Format-Table Name,Status,Present
$test = gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "Media" -and $_.Status -ne "OK"}

If ($test) {
  $STATUS= "KO"
  $EXIT = 2
} Else {
  $STATUS= "OK"
  $EXIT = 0
}

Write-Host "Audio: $STATUS"
$output
$host.SetShouldExit($EXIT)
