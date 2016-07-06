# Check shares script for Icinga2
# Require: Powershell script execution enabled
# v.20160422 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

param([string]$SHARESLIST = "shares")
$COUNT_SHARED = 0
$COUNT_UNSHARED = 0

$SHAREARRAY =  $SHARESLIST.replace('$','\$').split(" ")
  foreach($SHARE in $SHAREARRAY) {
    $CHECK = net share | Select-String -Pattern "$SHARE"
    $SHARE = $SHARE.replace('\$','$')
      If ($CHECK) {
	  if ($COUNT_SHARED -gt 0) { $SHARED += " " }
	$SHARED += "\\$env:computername\$SHARE"
	$COUNT_SHARED ++
      } else {
	  if ($COUNT_UNSHARED -gt 0) { $UNSHARED += " " }
	$UNSHARED += "\\$env:computername\$SHARE"
	$COUNT_UNSHARED ++
	$STATUS_CRITICAL = 1
      }
  }

  if ( $STATUS_CRITICAL ) {
    Write-Host -NoNewline "CRITICAL: $UNSHARED "
      if ($COUNT_UNSHARED -eq 1) {
	Write-Host -NoNewline "is"
      } else {
	Write-Host -NoNewline "are"
      }
    Write-Host "n't shared |"
    $EXIT = 1
  } else {
    Write-Host -NoNewline "OK: all shares were found ("
    Write-Host $SHARED") |"
    $EXIT = 0
  }
$host.SetShouldExit($EXIT)