# Check IcingaForWindows script for Icinga2
# Require: Powershell script execution enabled, IcingaForWindows framework
# v.20220404 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

param([string]$INVOKE, [string]$NAME, [string]$PARAMETERS)

If (! $INVOKE) {
  $EXIT = 2
  Write-Host "Missing invoke command patameter!"
  $host.SetShouldExit($EXIT)
}
If (! $NAME) {
  $EXIT = 2
  Write-Host "Missing name patameter!"
  $host.SetShouldExit($EXIT)
}

Use-Icinga

If ($INVOKE -eq "process") {
  Write-Host -NoNewline "$NAME "
  Invoke-IcingaCheckProcess -Process $NAME $PARAMETERS
  $EXIT = 0
} Else {
  $EXIT = 2
  Write-Host "Wrong invoke command!"
  $host.SetShouldExit($EXIT)
}


$host.SetShouldExit($EXIT)