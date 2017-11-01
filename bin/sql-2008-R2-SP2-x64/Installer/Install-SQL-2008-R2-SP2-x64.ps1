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

$pars=@($Temp)
foreach($part in @(1,2,3)) { 
   $pars += "https://github.com/devizer/glist/raw/master/bin/sql-2008-R2-SP2-x64/SQLEXPR-x86-ENU-2008-R2-SP2.7z.exe.7z.00$part"; 
}

pushd $Temp
cmd /c "$Essentials\Parallel-Download.exe" $pars
cmd /c "$Essentials\x86\7z.exe" @("x", "-y", "SQLEXPR-x86-ENU-2008-R2-SP2.7z.exe.7z.001")
cmd /c "$Essentials\x86\7z.exe" @("x", "-y", "SQLEXPR-x86-ENU-2008-R2-SP2.7z.exe")
ri SQLEXPR-x86-ENU-2008-R2-SP2.7z*
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
pushd "$temp\SQLEXPR-x86-ENU-2008-R2-SP2"
cmd /c setup.exe /Action=Install /ADDCURRENTUSERASSQLADMIN /IACCEPTSQLSERVERLICENSETERMS /ENU /FEATURES=SQLENGINE /INSTANCENAME=SQL2008R2SP2 /SECURITYMODE=SQL /SAPWD=`1qazxsw2PasS /TCPENABLED=1 /NPENABLED=1 /INDICATEPROGRESS /QS /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" /INSTANCEDIR="$target" /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS"
popd

Remove-Item -Recurse -Force "$temp\SQLEXPR-x86-ENU-2008-R2-SP2"
$exe="$target\MSSQL10_50.SQL2008R2SP2\MSSQL\Binn\sqlservr.exe"
cmd /c netsh firewall add allowedprogram `"$exe`" `"SQL Express 2008 R2 SP2 x86`" ENABLE
