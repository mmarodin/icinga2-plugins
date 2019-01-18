# Check interface traffic script for Icinga2
# Require: Powershell script execution enabled, check_network.exe from Icinga2 windows plugin
# v.20180329 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

$PLUGINDIR = "C:\Program Files\ICINGA2\sbin"
$TMPFILE = "C:\Windows\Temp\tmp_icinga2_int.Ethernet"

#Use with plugin v1.1
#& $PLUGINDIR'\check_network.exe' > $TMPFILE
#Get-Content $TMPFILE |  %{ $OUTPUT=$_.Split('|')[0]; }
#Get-Content $TMPFILE |  %{ $IN=$_.Split(';')[7]; }
##Get-Content $TMPFILE |  %{ $IN=$_.Split(';')[5]; }
#Get-Content $TMPFILE |  %{ $OUT=$_.Split(';')[8]; }
##Get-Content $TMPFILE |  %{ $_.Split(';')[6]; } | %{ $OUT=$_.Split(' ')[0]; }
#
#Write-Host $OUTPUT" | ethernet_"$IN" ethernet_"$OUT

#Use with plugin v1.2
& $PLUGINDIR'\check_network.exe' -n > $TMPFILE
Get-Content $TMPFILE |  %{ $OUTPUT=$_.Split('|')[0]; }
$(Get-Content $TMPFILE).Split('|')[1] | %{ $IN=$_.Split(' ')[2]; }
$(Get-Content $TMPFILE).Split('|')[1] | %{ $OUT=$_.Split(' ')[3]; }

Write-Host $OUTPUT" | $IN $OUT"
$host.SetShouldExit(0)