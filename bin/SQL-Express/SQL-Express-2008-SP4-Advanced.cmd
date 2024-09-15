@echo off

set KEY=SQL-Express-2008-SP4-x64-Advanced

if Not Defined NEW_SQL_INSTANCE_NAME (
  set NEW_SQL_INSTANCE_NAME=SQL_2008_ADV_SP4
)
echo Installing new instance [%NEW_SQL_INSTANCE_NAME%] of [%KEY%]

mkdir "%AppData%\Temp\%KEY%" 1>nul 2>&1

echo DOWNLOADING SETUP %KEY%
rem Advanced is RTM
set url_x86=https://download.microsoft.com/download/e/9/b/e9bcf5d7-2421-464f-94dc-0c694ba1b5a4/SQLEXPRADV_x86_ENU.exe
set url=https://download.microsoft.com/download/e/9/b/e9bcf5d7-2421-464f-94dc-0c694ba1b5a4/SQLEXPRADV_x64_ENU.exe
set outfile=%AppData%\Temp\%KEY%\Setup.exe
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; for ($i=1; $i -le 3; $i++) { $d=new-object System.Net.WebClient; try { $d.DownloadFile("$Env:url","$Env:outfile"); exit 0; } catch { Write-Host $_; Write-Host "Try $i of 3 failed for $($Env:url)" -ForegroundColor DarkRed; } } Exit 1  | powershell -command -
echo Extracting SETUP %KEY%
"%outfile%" /q /x:"%AppData%\Temp\%KEY%\Setup"
del /F /Q "%outfile%"

echo DOWNLOADING SERVICE PACK %KEY%
set url_x86=https://download.microsoft.com/download/5/E/7/5E7A89F7-C013-4090-901E-1A0F86B6A94C/ENU/SQLServer2008SP4-KB2979596-x86-ENU.exe
set url=https://download.microsoft.com/download/5/E/7/5E7A89F7-C013-4090-901E-1A0F86B6A94C/ENU/SQLServer2008SP4-KB2979596-x64-ENU.exe
set outfile=%AppData%\Temp\%KEY%\ServicePack.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; for ($i=1; $i -le 3; $i++) { $d=new-object System.Net.WebClient; try { $d.DownloadFile("$Env:url","$Env:outfile"); exit 0; } catch { Write-Host $_; Write-Host "Try $i of 3 failed for $($Env:url)" -ForegroundColor DarkRed; } } Exit 1  | powershell -command -
echo Extracting Service Pack %KEY%
"%outfile%" /q /x:"%AppData%\Temp\%KEY%\ServicePack"
del /F /Q "%outfile%"


Echo Install %KEY%
rem # https://docs.microsoft.com/en-us/previous-versions/sql/sql-server-2008/ms144259(v=sql.100)
rem /INDICATEPROGRESS
"%AppData%\Temp\%KEY%\Setup\Setup.exe" /Q /INDICATEPROGRESS /Action=Install ^
  /ADDCURRENTUSERASSQLADMIN ^
  /FEATURES=SQL ^
  /INSTANCENAME=%NEW_SQL_INSTANCE_NAME% ^
  /SECURITYMODE=SQL /SAPWD=`1qazxsw2 ^
  /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" ^
  /INSTANCEDIR="%SystemDrive%\SQL" ^
  /INSTALLSHAREDDIR="%SystemDrive%\SQL\x64b" ^
  /INSTALLSHAREDWOWDIR="%SystemDrive%\SQL\x86b" ^
  /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS" ^
  /TCPENABLED=1 /NPENABLED=1

echo Install Service Pack %KEY%
"%AppData%\Temp\%KEY%\ServicePack\Setup.exe" /Q /Action=Patch /instancename=%NEW_SQL_INSTANCE_NAME%

rd /q /s "%AppData%\Temp\%KEY%"
