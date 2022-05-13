# Check if file exists script for Icinga2
# Require: Powershell script execution enabled
# v.20220321 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

param([string]$PATH = "")

If ($PATH -eq "") {
  $PATH = "C:\Import\error\FILENAME.csv"
}

If (Test-Path $PATH) {
  $Time = $(Get-ChildItem -Path $PATH).LastWriteTime
  $Status = "CRITICAL - $PATH file modified on $Time"
  $Exit = 2
} Else {
  $Status = "OK - any $PATH file is present"
  $Exit = 0
}

Write-Host $Status

$host.SetShouldExit($Exit)