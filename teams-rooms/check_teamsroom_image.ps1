# Check Teams Room Logi Group Camera status script for Icinga2
# Require: Powershell script execution enabled
# v.20191129 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

$cam_status  = (gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "Image" -and $_.Name -eq "Logi Group Camera" }).Status
$cam_present = (gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "Image" -and $_.Name -eq "Logi Group Camera" }).Present

If (($cam_present) -and ($cam_status -eq "OK")) {
  $STATUS = "OK"
  $EXIT = 0
} Else {
  $STATUS = "KO"
  $EXIT = 2
}

Write-Host "Logi Group Camera status: $STATUS"
$host.SetShouldExit($EXIT)
