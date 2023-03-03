@echo off

set KEY=SQL-Express-2012-SP3-x64

if Not Defined NEW_SQL_INSTANCE_NAME (
  set NEW_SQL_INSTANCE_NAME=SQL_2012_SP3
)
echo Installing new instance [%NEW_SQL_INSTANCE_NAME%] of [%KEY%]

echo DOWNLOADING %KEY%.exe
set url=https://download.microsoft.com/download/F/6/7/F673709C-D371-4A64-8BF9-C1DD73F60990/ENU/x64/SQLEXPR_x64_ENU.exe
set outfile=%AppData%\Temp\%KEY%.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
rem echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; for ($i=1; $i -le 3; $i++) { $d=new-object System.Net.WebClient; try { $d.DownloadFile("$Env:url","$Env:outfile"); exit 0; } catch { Write-Host $_; Write-Host "Try $i of 3 failed for $($Env:url)" -ForegroundColor DarkRed; } } Exit 1  | powershell -command -

echo Extracting %KEY%.exe
"%outfile%" /q /x:"%AppData%\Temp\%KEY%"
del /F /Q "%outfile%"

"%AppData%\Temp\%KEY%\Setup.exe" /QUIETSIMPLE /ENU /INDICATEPROGRESS /ACTION=Install ^
  /IAcceptSQLServerLicenseTerms ^
  /UpdateEnabled=True ^
  /FEATURES=SQLENGINE,REPLICATION,SQL,RS,Tools,LocalDB ^
  /INSTANCENAME="%NEW_SQL_INSTANCE_NAME%" ^
  /INSTANCEDIR="%SystemDrive%\SQL" ^
  /SECURITYMODE="SQL" ^
  /SAPWD="`1qazxsw2" ^
  /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" ^
  /SQLSVCSTARTUPTYPE=AUTOMATIC ^
  /BROWSERSVCSTARTUPTYPE=AUTOMATIC ^
  /ADDCURRENTUSERASSQLADMIN ^
  /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" ^
  /TCPENABLED=1 /NPENABLED=1

rd /q /s "%AppData%\Temp\%KEY%"
