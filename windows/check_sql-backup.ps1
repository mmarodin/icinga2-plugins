# Check sql backup script for Icinga2
# Require: Powershell script execution enabled
# v.20180112 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins
#

$USERNAME = "icinga2"
$PASSWORD = "********"
$QUERYDBS = "SELECT name FROM master.dbo.sysdatabases WHERE name not in ('model', 'tempdb', 'CUSTOMEXAMPLE') AND name NOT LIKE 'DW%'"
$QUERYBCK = "SELECT CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server, msdb.dbo.backupset.database_name, msdb.dbo.backupset.backup_start_date, msdb.dbo.backupset.backup_finish_date, msdb.dbo.backupset.expiration_date, CASE msdb..backupset.type WHEN 'D' THEN 'Database' WHEN 'L' THEN 'Log' END AS backup_type, msdb.dbo.backupset.backup_size, msdb.dbo.backupmediafamily.logical_device_name,msdb.dbo.backupmediafamily.physical_device_name, msdb.dbo.backupset.name AS backupset_name, msdb.dbo.backupset.description FROM msdb.dbo.backupmediafamily INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id WHERE msdb..backupset.type = 'D'and (CONVERT(date, msdb.dbo.backupset.backup_start_date, 102) = CONVERT(VARCHAR(10),GETDATE(),10))"

$DBS = $(Invoke-Sqlcmd -Username $USERNAME -Password $PASSWORD -Query $QUERYDBS).Name
#$DBS

If (!$DBS) {
  $host.SetShouldExit(2)
  exit
}

foreach ($DBNAME in $DBS) {
  $BCK = $(Invoke-Sqlcmd -Username $USERNAME -Password $PASSWORD -Query "$QUERYBCK and msdb.dbo.backupset.database_name = '$DBNAME'")

  if (! $BCK) {
    #Write-Host $DBNAME": KO"
    $CHECK += " $DBNAME"
  }

  #$BCK
}

if ($CHECK) {
  Write-Host "CRITICAL - Backup with problem:$CHECK"
  $EXIT = 2
} else {
  Write-Host "OK - Databases are backuped up correctly"
 $EXIT = 0 
}

$host.SetShouldExit($EXIT)