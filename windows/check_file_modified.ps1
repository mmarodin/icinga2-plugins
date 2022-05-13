# Check file modified script for Icinga2
# Require: Powershell script execution enabled
# v.20211025 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

param([string]$PATH = "", [string]$DAYS = "5", [string]$EXT = "txt")

If ($PATH -eq "") {
  Write-Host Missing path name!
  cmd /c pause
  Exit(1)
}

If (!(Test-Path $PATH)) {
  Write-Host Path name does not exists!
  cmd /c pause
  Exit(1)
}

$Count = $(Get-ChildItem -Path $PATH\*.* -Filter *.$EXT | ? {$_.LastWriteTime -gt (Get-Date).AddDays(-$DAYS)}).Count

If ($Count -eq 0) {
  $Status = "CRITICAL"
  $Exit = 2
} Else {
  $Status = "OK"
  $Exit = 0
}

Write-Host $Status - $Count file`(s`) modified in the last $DAYS day`(s`)`| `'files`'=$Count

$host.SetShouldExit($Exit)