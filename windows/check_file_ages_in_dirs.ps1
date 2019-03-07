# Check file ages in a directory script for Icinga2
# Require: Powershell script execution enabled
# v.20190301 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

param([string]$PATH = "", [string]$WARNING = "12", [string]$CRITICAL = "24")

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

$WarnDate = (Get-Date).AddHours(-$WARNING)
$CritDate = (Get-Date).AddHours(-$CRITICAL)

$CritCount = $(Get-ChildItem -Path $PATH -File | Where-Object {$_.LastWriteTime -le $CritDate}).Count
$WarnCount = $(Get-ChildItem -Path $PATH -File | Where-Object {$_.LastWriteTime -le $WarnDate -and $_.LastWriteTime -gt $CritDate}).Count
$OkCount = $(Get-ChildItem -Path $PATH -File | Where-Object {$_.LastWriteTime -gt $WarnDate}).Count
$TotalCount = $(Get-ChildItem -Path $PATH -File).Count

If ($CritCount -ge 1) {
  $Status = "CRITICAL"
  $Exit = 2
} ElseIf ($WarnCount -ge 1) {
  $Status = "WARNING"
  $Exit = 1
} Else {
  $Status = "OK"
  $Exit = 0
}

Write-Host $Status - Ok: $OkCount file`(s`): Critical: $CritCount file`(s`): Warning: $WarnCount file`(s`): $PATH`: $TotalCount files `| `'files_ok`'=$OkCount `'files_crit`'=$CritCount `'files_warn`'=$WarnCount `'files_count`'=$TotalCount

$host.SetShouldExit($Exit)