@echo off

set v=2012-DEV
set KEY=SQL-%v%

if Not Defined NEW_SQL_INSTANCE_NAME (
  set NEW_SQL_INSTANCE_NAME=DEVELOPER_2022
)
echo Installing new instance [%NEW_SQL_INSTANCE_NAME%] of [%KEY%]

echo DOWNLOADING SQL %v% BOOTSTRAPPER
set url=https://download.microsoft.com/download/e/9/5/e95d4bc4-1834-477f-8444-09d848202c87/SQL2022-SSEI-Eval.exe
rem set url=https://download.microsoft.com/download/4/1/b/41b9a8c3-c2b4-4fcc-a3d5-62feed9e6885/SQL2022-SSEI-Eval.exe?culture=en-us^&country=us
set url=https://download.microsoft.com/download/4/1/b/41b9a8c3-c2b4-4fcc-a3d5-62feed9e6885/SQL2022-SSEI-Eval.exe
set outfile=%AppData%\Temp\%KEY%.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -

echo DOWNLOADING SQL %v%
echo Y | "%outfile%" /ENU /Q /Action=Download /MEDIATYPE=CAB /MEDIAPATH="%AppData%\Temp\%KEY%"
set file=SQLEXPR_x64_ENU.exe
echo "DIR CONTENT"
dir "%AppData%\Temp\%KEY%"
"%AppData%\Temp\%KEY%\SQLServer2022-x64-ENU.exe" /qs /x:"%AppData%\Temp\%KEY%\extracted"
del /q "%AppData%\Temp\%KEY%\SQLServer2022-x64-ENU.exe" >nul 2>&1

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

"%AppData%\Temp\%KEY%\extracted\Setup.exe" /QUIETSIMPLE /ENU /INDICATEPROGRESS /ACTION=Install ^
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

rd /q /s "%AppData%\Temp\%KEY%"