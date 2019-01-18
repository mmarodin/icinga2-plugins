# Check Oracle DB connection script for Icinga2
# Require: Powershell script execution enabled, sqlplus
# v.20181120 by mmarodin
#
# https://github.com/mmarodin/icinga2-plugins

$USERNAME = "username"
$INSTANCE = "dbname"

$sqlQuery = @"
	set NewPage none
	set heading off
	set feedback off
	SELECT username FROM dba_users WHERE username = 'test';
	exit
"@

$QUERY = $sqlQuery | sqlplus $USERNAME/$USERNAME@$INSTANCE

  if ($LASTEXITCODE -eq 0) {
    Write-Host OK - dummy login connected
    $EXIT=0
  } else {
    Write-Host CRITICAL - not connecting
    $EXIT=2
  }

$host.SetShouldExit($EXIT)