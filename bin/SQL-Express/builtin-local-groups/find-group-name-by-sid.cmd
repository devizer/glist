PWERSHELL v5 is required
for /f "delims=;" %%i in ('powershell -command "$_=(Get-LocalGroup | where { $_.sid -eq \"S-1-5-32-545\" }); if ($_.Length -gt 0) { $groupName = $_[0].Name } else { $groupName = $null }; Write-host $groupName"') DO set groupname=%%i
echo GROUP NAME [%groupname%]
pause
