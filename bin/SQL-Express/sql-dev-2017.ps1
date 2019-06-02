$v=2017
$KEY="SQL-Dev-$v-SP-x64"
$url="https://download.microsoft.com/download/5/A/7/5A7065A2-C81C-4A31-9972-8A31AC9388C1/SQLServer2017-SSEI-Dev.exe"
$outfile="${Env:AppData}\Temp\$KEY.exe"
Write-Host "DOWNLOADING SQL $v BOOTSTRAPPER into `"$outfile`""
New-Item "${Env:AppData}\Temp" -type directory -force -EA SilentlyContinue | out-null
$sys=$Env:SystemDrive; if (-not $sys) { $sys="C:\" }; $sys=$sys.ToUpper().TrimEnd([char]92);

# ADDCURRENTUSERASSQLADMIN="True" can be used for Express edition or set by ROLE :(

'
[OPTIONS]
ACTION="Install"
SUPPRESSPRIVACYSTATEMENTNOTICE="True"
IACCEPTROPENLICENSETERMS="True"
ENU="True"
QUIET="False"
QUIETSIMPLE="False"
UpdateEnabled="True"
USEMICROSOFTUPDATE="True"
UpdateSource="MU"
FEATURES=SQLENGINE,REPLICATION,FULLTEXT
HELP="False"
INDICATEPROGRESS="False"
X86="False"
INSTANCENAME="SQL_DEV_2017"
INSTANCEID="SQL_DEV_2017"
SQLTELSVCACCT="NT Service\SQLTELEMETRY$SQL_DEV_2017"
SQLTELSVCSTARTUPTYPE="Disabled"
INSTANCEDIR="' + $sys + '\SQL"
INSTALLSHAREDDIR="' + $sys + '\SQL\x64"
INSTALLSHAREDWOWDIR="' + $sys + '\SQL\x86"
AGTSVCACCOUNT="NT AUTHORITY\SYSTEM"
AGTSVCSTARTUPTYPE="Manual"
COMMFABRICPORT="0"
COMMFABRICNETWORKLEVEL="0"
COMMFABRICENCRYPTION="0"
MATRIXCMBRICKCOMMPORT="0"
SQLSVCSTARTUPTYPE="Automatic"
FILESTREAMLEVEL="1"
ENABLERANU="False"
SQLCOLLATION="Latin1_General_CI_AS"
SQLSVCACCOUNT="NT AUTHORITY\SYSTEM"
SQLSVCINSTANTFILEINIT="True"
SQLSYSADMINACCOUNTS="BUILTIN\Users"
ADDCURRENTUSERASSQLADMIN="False"
SECURITYMODE="SQL"
SAPWD="`1qazxsw2"
SQLTEMPDBFILECOUNT="2"
SQLTEMPDBFILESIZE="8"
SQLTEMPDBFILEGROWTH="64"
SQLTEMPDBLOGFILESIZE="8"
SQLTEMPDBLOGFILEGROWTH="64"
TCPENABLED="1"
NPENABLED="1"
BROWSERSVCSTARTUPTYPE="Manual"
' > "${Env:AppData}\Temp\2017-DEV.ini"

[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; 
$d.DownloadFile("$url","$outfile")

pushd "${Env:AppData}\Temp"
& cmd /c "$KEY.exe" /ENU /IAcceptSqlServerLicenseTerms /Quiet /Verbose /ConfigurationFile=.\2017-DEV.ini /Action=Install /Language=en-US /InstallPath="${Env:SystemDrive}\SQL"
popd

& cmd /c rd /q /s "${Env:SystemDrive}\SQLServer2017Media\Developer_ENU"

"Done"
