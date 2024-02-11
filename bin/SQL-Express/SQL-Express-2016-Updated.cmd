@echo off

set v=2016-Express
echo DOWNLOADING SQL Express %v%
set KEY=SQL-%v%-SP-x64

if Not Defined NEW_SQL_INSTANCE_NAME (
  set NEW_SQL_INSTANCE_NAME=SQL_2016
)
echo Installing new instance [%NEW_SQL_INSTANCE_NAME%] of [%KEY%]

If Defined TEMP (
  set Work=%TEMP%\%KEY%
  Rem echo Creating Archive and Setup Folder "%TEMP%\%KEY%"
  mkdir "%TEMP%\%KEY%" 1>nul 2>&1
)
If Not Exist "%Work%" Set "Work="
If Not Defined Work (
  If Defined LocalAppData (Set Work=%LocalAppData%\Temp\%KEY%) Else (Set Work=%AppData%\Temp\%KEY%)
  mkdir "%Work%" 1>nul 2>&1
)


set url=https://download.microsoft.com/download/9/0/7/907AD35F-9F9C-43A5-9789-52470555DB90/ENU/SQLEXPR_x64_ENU.exe
rem SP3
set url=https://download.microsoft.com/download/f/9/8/f982347c-fee3-4b3e-a8dc-c95383aa3020/sql16_sp3_dlc/en-us/SQLEXPR_x64_ENU.exe
set outfile=%Work%\%KEY%.exe
echo %KEY% Archive and Setup Folder: [%Work%]
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; for ($i=1; $i -le 3; $i++) { $d=new-object System.Net.WebClient; try { $d.DownloadFile("$Env:url","$Env:outfile"); exit 0; } catch { Write-Host $_; Write-Host "Try $i of 3 failed for $($Env:url)" -ForegroundColor DarkRed; } } Exit 1  | powershell -command -

echo EXTRACTING SQL %v%
"%outfile%" /qs /x:"%Work%\SETUPFILES\extracted"
del /q "%outfile%" >nul 2>&1

echo Starting Setup.exe
"%Work%\SETUPFILES\extracted\Setup.exe" /QUIETSIMPLE /ENU /INDICATEPROGRESS /ACTION=Install ^
  /IAcceptSQLServerLicenseTerms /IACCEPTROPENLICENSETERMS ^
  /UpdateEnabled=True ^
  /FEATURES=SQLENGINE,REPLICATION,SQL ^
  /INSTANCENAME="%NEW_SQL_INSTANCE_NAME%" ^
  /INSTANCEDIR="%SystemDrive%\SQL" ^
  /INSTALLSHAREDDIR="%SystemDrive%\SQL\x64" ^
  /INSTALLSHAREDWOWDIR="%SystemDrive%\SQL\x86" ^
  /SECURITYMODE="SQL" ^
  /SAPWD="`1qazxsw2" ^
  /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" ^
  /SQLSVCSTARTUPTYPE=AUTOMATIC ^
  /BROWSERSVCSTARTUPTYPE=AUTOMATIC ^
  /ADDCURRENTUSERASSQLADMIN ^
  /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" ^
  /TCPENABLED=1 /NPENABLED=1

rd /q /s "%Work%"
