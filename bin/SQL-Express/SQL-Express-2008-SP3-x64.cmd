@echo off

set KEY=SQL-Express-2008-SP3-x64

if Not Defined NEW_SQL_INSTANCE_NAME (
  set NEW_SQL_INSTANCE_NAME=SQL_2008_SP3
)
echo Installing new instance [%NEW_SQL_INSTANCE_NAME%] of [%KEY%]

echo DOWNLOADING %KEY%.exe
rem EXPIRED
set url=https://download.microsoft.com/download/0/F/D/0FD88169-F86F-46E1-8B3B-56C44F6E9505/SQLEXPR_x64_ENU.exe
set url=https://dl.bintray.com/devizer/archive/database-engine-x64-10.0.5500.exe/database-engine-x64-10.0.5500.exe
set url=https://master.dl.sourceforge.net/project/db-engine/database-engine-x64-10.0.5500.exe?viasf=1
set outfile=%AppData%\Temp\%KEY%.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
rem echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; for ($i=1; $i -le 3; $i++) { $d=new-object System.Net.WebClient; try { $d.DownloadFile("$Env:url","$Env:outfile"); exit 0; } catch { Write-Host $_; Write-Host "Try $i of 3 failed for $($Env:url)" -ForegroundColor DarkRed; } } Exit 1  | powershell -command -

echo Extracting %KEY%.exe
@rem Suppress both GUI and "Extract completed" Message Box
"%outfile%" /q /x:"%AppData%\Temp\%KEY%"
del /F /Q "%outfile%"

rem # https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008/ms144259(v=sql.100)
"%AppData%\Temp\%KEY%\Setup.exe" /QS /INDICATEPROGRESS /Action=Install ^
  /ADDCURRENTUSERASSQLADMIN ^
  /FEATURES=SQLENGINE ^
  /INSTANCENAME=%NEW_SQL_INSTANCE_NAME% ^
  /SECURITYMODE=SQL /SAPWD=`1qazxsw2 ^
  /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" ^
  /INSTANCEDIR="%SystemDrive%\SQL" ^
  /INSTALLSHAREDDIR="%SystemDrive%\SQL\x64b" ^
  /INSTALLSHAREDWOWDIR="%SystemDrive%\SQL\x86b" ^
  /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" ^
  /TCPENABLED=1 /NPENABLED=1 

rd /q /s "%AppData%\Temp\%KEY%"
