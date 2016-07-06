# Check interface traffic script for Icinga2
# Require: Powershell script execution enabled, 'check_network.exe' script from Icinga2 Windows plugin
# v.20160610 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

$PLUGINDIR = "C:\Program Files\ICINGA2\sbin"
$TMPFILE = "C:\Windows\Temp\tmp_icinga2_int.Ethernet"

& $PLUGINDIR'\check_network.exe' > $TMPFILE
Get-Content $TMPFILE |  %{ $OUTPUT=$_.Split('|')[0]; }
Get-Content $TMPFILE |  %{ $IN=$_.Split(';')[7]; }
#Get-Content $TMPFILE |  %{ $IN=$_.Split(';')[5]; }
Get-Content $TMPFILE |  %{ $OUT=$_.Split(';')[8]; }
#Get-Content $TMPFILE |  %{ $_.Split(';')[6]; } | %{ $OUT=$_.Split(' ')[0]; }

Write-Host $OUTPUT" | ethernet_"$IN" ethernet_"$OUT
$host.SetShouldExit(0)