@echo off

set v=2014-SP2-Express-with-Tools
set KEY=SQL-%v%

if Not Defined NEW_SQL_INSTANCE_NAME (
  set NEW_SQL_INSTANCE_NAME=ADV_2014_SP2
)
echo Installing new instance [%NEW_SQL_INSTANCE_NAME%] of [%KEY%]

echo DOWNLOADING SQL %v% (about 1.4 Gb)
Set url64=https://download.microsoft.com/download/2/A/5/2A5260C3-4143-47D8-9823-E91BB0121F94/SQLEXPRADV_x64_ENU.exe
Set url86=https://download.microsoft.com/download/2/A/5/2A5260C3-4143-47D8-9823-E91BB0121F94/SQLEXPRADV_x86_ENU.exe
If "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  Set url=%url64% 
  Set Shared=x64
  Set WOW=/INSTALLSHAREDWOWDIR="%SystemDrive%\SQL\x86"
) Else (
  Set url=%url86%
  Set Shared=x86
)
set outfile=%AppData%\Temp\%KEY%.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -

for /f "delims=;" %%i in ('powershell -command "(Get-WmiObject -Class Win32_Group | where { $_.SID -eq \"S-1-5-32-545\" }).Name"') DO set users=%%i
If Not Defined users Set users=Users

pushd "%AppData%\Temp"
rem SQLENGINE,REPLICATION,FullText
Echo On
"%outfile%" /QS /Action=Install /ADDCURRENTUSERASSQLADMIN /IACCEPTSQLSERVERLICENSETERMS /ENU /FEATURES=SQLENGINE,REPLICATION,FullText /INSTANCENAME=%NEW_SQL_INSTANCE_NAME% /SECURITYMODE=SQL /SAPWD="`1qazxsw2" /TCPENABLED=1 /NPENABLED=1 /INDICATEPROGRESS /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" /INSTANCEDIR="%SystemDrive%\SQL" /INSTALLSHAREDDIR="%SystemDrive%\SQL\%Shared%" %WOW% /SQLSYSADMINACCOUNTS="BUILTIN\%USERS%"
@echo off
popd


del /q "%outfile%" >nul 2>&1
rd /q /s "%AppData%\Temp\%KEY%"
