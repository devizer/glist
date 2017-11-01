$files=$("Essentials.7z.exe")
$baseUrl="https://raw.githubusercontent.com/devizer/glist/master/Essentials/"
$Temp="$($Env:LocalAppData)"
$Essentials="$Temp\Temp\Essentials"
Write-Host "Essentials folder: $Essentials"
New-Item $Essentials -type directory -force -EA SilentlyContinue | out-null
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true};
foreach($file in $files) {
 $d=new-object System.Net.WebClient; $d.DownloadFile("$baseurl/$file","$Essentials\$file");
}
pushd $Essentials
cmd /c Essentials.7z.exe -y
ri Essentials.7z.exe
popd
# Done: Essentials

$pars=@($Temp, "https://github.com/devizer/glist/bin/sql-2005-SP4-x86/SQL-Express-2005-SP4-x86.7z.exe")

pushd $Temp
cmd /c "$Essentials\Parallel-Download.exe" $pars
cmd /c "$Essentials\x86\7z.exe" @("x", "-y", "SQL-Express-2005-SP4-x86.7z.exe")
ri SQL-Express-2005-SP4-x86.7z*
popd

Write-Host "Installing .NET 3.5 and 4.5"
Add-WindowsFeature Net-Framework-Core
Add-WindowsFeature NET-Framework-45-Core
pushd $Env:windir\microsoft.net
Framework64\v2.0.50727\ngen.exe  queue pause
Framework64\v4.0.30319\ngen.exe  queue pause
Framework\v2.0.50727\ngen.exe    queue pause
Framework\v4.0.30319\ngen.exe    queue pause
popd

$target="C:\SQL"
pushd "$temp\SQL-Express-2005-SP4-x86"
cmd /c setup.exe /qb ADDLOCAL=SQL_Engine INSTANCENAME=SQL2005SP4 DISABLENETWORKPROTOCOLS=0 SECURITYMODE=SQL SAPWD=`1qazxsw2 INSTALLSQLDIR="$target"
popd

Remove-Item -Recurse -Force "$temp\SQL-Express-2005-SP4-x86"
$exe="$target\MSSQL.1\MSSQL\Binn\sqlservr.exe"
cmd /c netsh firewall add allowedprogram `"$exe`" `"SQL Express 2005 SP4 x86`" ENABLE
