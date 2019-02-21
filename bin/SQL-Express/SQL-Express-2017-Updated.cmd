@echo off

set v=2017
set KEY=SQL-Express-%v%-SP-x64
echo DOWNLOADING SQL Express %v% BOOTSTRAPPER
set url=https://raw.githubusercontent.com/devizer/glist/master/bin/sql-2017-Express/SQLServer2017-SSEI-Expr.exe
set outfile=%AppData%\Temp\%KEY%.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -

echo DOWNLOADING SQL Express %v%
echo Y | "%outfile%" /ENU /Q /Action=Download /MEDIATYPE=Core /MEDIAPATH="%AppData%\Temp\%KEY%"
set file=SQLEXPR_x64_ENU.exe
dir "%AppData%\Temp\%KEY%\SQLEXPR_x64_ENU.exe"
"%AppData%\Temp\%KEY%\SQLEXPR_x64_ENU.exe" /qs /x:"%AppData%\Temp\%KEY%\extracted"

"%AppData%\Temp\%KEY%\extracted\Setup.exe" /QUIETSIMPLE /ENU /INDICATEPROGRESS /ACTION=Install ^
  /IAcceptSQLServerLicenseTerms /IACCEPTROPENLICENSETERMS ^
  /UpdateEnabled=True ^
  /FEATURES=SQLENGINE,REPLICATION,SQL,RS,Tools,LocalDB ^
  /INSTANCENAME="SQL_2017" ^
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

rd /q /s "%AppData%\Temp\%KEY%"
