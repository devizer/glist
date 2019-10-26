@echo off

set KEY=SQL-Express-2014-SP1-x64

if Not Defined NEW_SQL_INSTANCE_NAME (
  set NEW_SQL_INSTANCE_NAME=SQL_2014_SP1
)
echo Installing new instance [%NEW_SQL_INSTANCE_NAME%] for [%KEY%]

echo DOWNLOADING %KEY%.exe
set url=https://download.microsoft.com/download/1/5/6/156992E6-F7C7-4E55-833D-249BD2348138/ENU/x64/SQLEXPR_x64_ENU.exe
set outfile=%AppData%\Temp\%KEY%.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -

echo Extracting %KEY%.exe
"%outfile%" /qs /x:"%AppData%\Temp\%KEY%"
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
