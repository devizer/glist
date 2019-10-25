@echo off

set v=2019-RC1
set KEY=SQL-%v%
echo DOWNLOADING SQL %v% BOOTSTRAPPER
set url=https://download.microsoft.com/download/f/7/1/f710f0db-9d30-4ec5-b0ad-f65529493f44/SQL2019RC1-SSEI-Eval.exe
set outfile=%AppData%\Temp\%KEY%.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -

echo DOWNLOADING SQL %v%
echo Y | "%outfile%" /ENU /Q /Action=Download /MEDIATYPE=CAB /MEDIAPATH="%AppData%\Temp\%KEY%"
set file=SQLEXPR_x64_ENU.exe
"%AppData%\Temp\%KEY%\SQLServer2019-x64-ENU.exe" /qs /x:"%AppData%\Temp\%KEY%\extracted"
del /q "%AppData%\Temp\%KEY%\SQLServer2019-x64-ENU.exe" >nul 2>&1

rem The supported features on Windows Server Core are: 
rem   Database Engine Services, 
rem   SQL Server Replication, 
rem   Full-Text and Semantic Extractions for Search, 
rem   Analysis Services, 
rem   Client Tools Connectivity, 
rem   Integration Services, 
rem   and SQL Client Connectivity SDK.

"%AppData%\Temp\%KEY%\extracted\Setup.exe" /QUIETSIMPLE /ENU /INDICATEPROGRESS /ACTION=Install ^
  /IAcceptSQLServerLicenseTerms /IACCEPTROPENLICENSETERMS ^
  /UpdateEnabled=True ^
  /FEATURES=SQLENGINE,REPLICATION,FullText ^
  /INSTANCENAME="SQL_2019_RC" ^
  /INSTANCEDIR="%SystemDrive%\SQL" ^
  /INSTALLSHAREDDIR="%SystemDrive%\SQL\x64" ^
  /INSTALLSHAREDWOWDIR="%SystemDrive%\SQL\x86" ^
  /SECURITYMODE="SQL" ^
  /SAPWD="`1qazxsw2" ^
  /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" ^
  /SQLSVCSTARTUPTYPE=AUTOMATIC ^
  /BROWSERSVCSTARTUPTYPE=AUTOMATIC ^
  /ADDCURRENTUSERASSQLADMIN=False ^
  /SQLSYSADMINACCOUNTS="BUILTIN\USERS" ^
  /TCPENABLED=1 /NPENABLED=1

rd /q /s "%AppData%\Temp\%KEY%"
