# Check disk status script for Icinga2
# Require: Powershell script execution enabled, 'check_disk.exe' script from Icinga2 Windows plugin
# Always return OK state
# v.20160421 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

$PLUGINDIR = "C:\Program Files\ICINGA2\sbin"
$TMPFILE = "C:\Windows\Temp\tmp_icinga2_disk.status"

& $PLUGINDIR'\check_disk.exe' -w 20% -c 10% > $TMPFILE
Get-Content $TMPFILE | %{ $OUTPUT=$_.Split('|')[0]; }
Get-Content $TMPFILE | %{ $PERFDATA=$_.Split('|')[1]; }
$OUTPUT.Substring(0,$OUTPUT.Length-1) | Out-file $TMPFILE
Get-Content $TMPFILE |  %{ $OUTPUT=$_.Split("-")[1]; }

Write-Host "DISK STATUS -"$OUTPUT.Substring(1)"|"$PERFDATA.Substring(1)
$host.SetShouldExit(0)