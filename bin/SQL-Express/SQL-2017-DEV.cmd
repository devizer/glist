@echo off

set v=2017-DEV
set KEY=SQL-%v%

if Not Defined NEW_SQL_INSTANCE_NAME (
  set NEW_SQL_INSTANCE_NAME=DEVELOPER_2017
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


echo DOWNLOADING SQL %v% BOOTSTRAPPER
set url=https://download.microsoft.com/download/5/A/7/5A7065A2-C81C-4A31-9972-8A31AC9388C1/SQLServer2017-SSEI-Dev.exe
set outfile=%Work%\%KEY%.exe
echo %KEY% Archive and Setup Folder: [%Work%]
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; for ($i=1; $i -le 3; $i++) { $d=new-object System.Net.WebClient; try { $d.DownloadFile("$Env:url","$Env:outfile"); exit 0; } catch { Write-Host $_; Write-Host "Try $i of 3 failed for $($Env:url)" -ForegroundColor DarkRed; } } Exit 1  | powershell -command -


echo DOWNLOADING SQL %v%
echo Y | "%outfile%" /ENU /Q /Action=Download /MEDIATYPE=CAB /MEDIAPATH="%Work%\SETUPFILES"
set file=SQLEXPR_x64_ENU.exe
echo "Extracting Content"
"%Work%\SETUPFILES\SQLServer2017-DEV-x64-ENU.exe" /qs /x:"%Work%\SETUPFILES\extracted"
del /q "%Work%\SETUPFILES\SQLServer2017-DEV-x64-ENU.exe" >nul 2>&1

rem The supported features on Windows Server Core are: 
rem   Database Engine Services, 
rem   SQL Server Replication, 
rem   Full-Text and Semantic Extractions for Search, 
rem   Analysis Services, 
rem   Client Tools Connectivity, 
rem   Integration Services, 
rem   and SQL Client Connectivity SDK.

for /f "delims=;" %%i in ('powershell -command "(Get-WmiObject -Class Win32_Group | where { $_.SID -eq \"S-1-5-32-545\" }).Name"') DO set users=%%i
If Not Defined users Set users=Users

"%Work%\SETUPFILES\extracted\Setup.exe" /QUIETSIMPLE /ENU /INDICATEPROGRESS /ACTION=Install ^
  /IAcceptSQLServerLicenseTerms /IACCEPTROPENLICENSETERMS ^
  /UpdateEnabled=True ^
  /FEATURES=SQLENGINE,REPLICATION,FullText ^
  /INSTANCENAME="%NEW_SQL_INSTANCE_NAME%" ^
  /INSTANCEDIR="%SystemDrive%\SQL" ^
  /INSTALLSHAREDDIR="%SystemDrive%\SQL\x64" ^
  /INSTALLSHAREDWOWDIR="%SystemDrive%\SQL\x86" ^
  /SECURITYMODE="SQL" ^
  /SAPWD="`1qazxsw2" ^
  /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" ^
  /SQLSVCSTARTUPTYPE=AUTOMATIC ^
  /BROWSERSVCSTARTUPTYPE=AUTOMATIC ^
  /ADDCURRENTUSERASSQLADMIN=False ^
  /SQLSYSADMINACCOUNTS="BUILTIN\%USERS%" ^
  /TCPENABLED=1 /NPENABLED=1

rd /q /s "%Work%"