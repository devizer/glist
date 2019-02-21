$files=$("Essentials.7z.exe")
$baseUrl="https://raw.githubusercontent.com/devizer/glist/master/Essentials/"
$Temp="$($Env:LocalAppData)"; if ($Temp -eq "") { $Temp="$($Env:UserProfile)"; }
$Temp="$Temp\Temp"
$Essentials="$Temp\Essentials"
Write-Host "Essentials folder: [$Essentials]" -foregroundcolor "magenta"
New-Item $Essentials -type directory -force -EA SilentlyContinue | out-null
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true};
foreach($file in $files) {
 $d=new-object System.Net.WebClient; $d.DownloadFile("$baseurl/$file","$Essentials\$file");
}
pushd $Essentials
& .\Essentials.7z.exe -y
ri Essentials.7z.exe
popd
$_7_Zip="$Essentials\x64\7z.exe";  if ( -Not ("$($Env:PROCESSOR_ARCHITECTURE)" -eq "AMD64")) { $_7_Zip="$Essentials\x86\7z.exe"; }
Write-Host "Architecture: $($Env:PROCESSOR_ARCHITECTURE). 7-Zip: [$_7_Zip]" -foregroundcolor "magenta"; 


$pars=@($Temp)
foreach($part in @(1,2,3)) { 
   $pars += "https://raw.githubusercontent.com/devizer/glist/master/bin/sql-2008-R2-SP2-x86/SQLEXPR-x86-ENU-2008-R2-SP2.7z.exe.7z.00$part"; 
}

pushd $Temp
& "$Essentials\Parallel-Download.exe" $pars
& $_7_Zip @("x", "-y", "SQLEXPR-x86-ENU-2008-R2-SP2.7z.exe.7z.001")
& $_7_Zip @("x", "-y", "SQLEXPR-x86-ENU-2008-R2-SP2.7z.exe")
ri SQLEXPR-x86-ENU-2008-R2-SP2.7z*
popd

Write-Host "Installing .NET 3.5 and 4.5"
Add-WindowsFeature Net-Framework-Core -EA SilentlyContinue
Add-WindowsFeature NET-Framework-45-Core -EA SilentlyContinue
pushd "$Env:windir\microsoft.net"
& Framework64\v2.0.50727\ngen.exe  queue pause
& Framework64\v4.0.30319\ngen.exe  queue pause
& Framework\v2.0.50727\ngen.exe    queue pause
& Framework\v4.0.30319\ngen.exe    queue pause
popd

$target="C:\SQL";
$t64="C:\SQL\x64"; 
$t86="C:\SQL\x86";
pushd "$temp\SQLEXPR-x86-ENU-2008-R2-SP2"
cmd /c .\setup.exe /QS /Action=Install /ADDCURRENTUSERASSQLADMIN /IACCEPTSQLSERVERLICENSETERMS /ENU /FEATURES=SQLENGINE /INSTANCENAME=SQL_2008_R2_SP2_x86 /SECURITYMODE=SQL /SAPWD=``1qazxsw2 /TCPENABLED=1 /NPENABLED=1 /INDICATEPROGRESS /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" /INSTANCEDIR="$target" /INSTALLSHAREDDIR="$t64" /INSTALLSHAREDWOWDIR="$t86" /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS"

popd

Remove-Item -Recurse -Force "$temp\SQLEXPR-x86-ENU-2008-R2-SP2"
$exe="$target\MSSQL10_50.SQL2008R2SP2\MSSQL\Binn\sqlservr.exe"
& netsh firewall add allowedprogram `"$exe`" `"SQL Express 2008 R2 SP2 x86`" ENABLE
