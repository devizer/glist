$files=$("Essentials.7z.exe")
$baseUrl="https://raw.githubusercontent.com/devizer/glist/master/Essentials/"
$Temp="$($Env:LocalAppData)"; if ($Temp -eq "") { $Temp="$($Env:UserProfile)"; }
$Temp="$Temp\Temp"
$Essentials="$Temp\Essentials"
Write-Host "Essentials folder: $Essentials"
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
Write-Host "Architecture: $($Env:PROCESSOR_ARCHITECTURE). 7-Zip: $_7_Zip";


$pars=@($Temp)
foreach($part in @(1,2)) { 
   $pars += "https://raw.githubusercontent.com/devizer/glist/master/bin/sql-2008-x64/SQL-Express-2008-x64.7z.7z.00$part";
}

pushd $Temp
& "$Essentials\Parallel-Download.exe" $pars
& $_7_Zip @("x", "-y", "SQL-Express-2008-x64.7z.7z.001")
& $_7_Zip @("x", "-y", "SQL-Express-2008-x64.7z")
ri SQL-Express-2008-x64.7z*
popd

Write-Host "Installing .NET 3.5 and 4.5"
Add-WindowsFeature Net-Framework-Core -EA SilentlyContinue
Add-WindowsFeature NET-Framework-45-Core -EA SilentlyContinue
Install-WindowsFeature Net-Framework-Core -EA SilentlyContinue
Install-WindowsFeature NET-Framework-45-Core -EA SilentlyContinue
pushd "$Env:windir\microsoft.net"
& Framework64\v2.0.50727\ngen.exe  queue pause
& Framework64\v4.0.30319\ngen.exe  queue pause
& Framework\v2.0.50727\ngen.exe    queue pause
& Framework\v4.0.30319\ngen.exe    queue pause
popd

$target="C:\SQL"
pushd "$temp\SQL-Express-2008-x64"
# 2008 RTM QS setup fails, but fully quiet works fine!
cmd /c setup.exe /Q /Action=Install /ADDCURRENTUSERASSQLADMIN /FEATURES=SQLENGINE /INSTANCENAME=SQL_2008_RTM /SECURITYMODE=SQL /SAPWD=``1qazxsw2 /TCPENABLED=1 /NPENABLED=1 /INDICATEPROGRESS  /SQLSVCACCOUNT="NT AUTHORITY\SYSTEM" /INSTANCEDIR="$target" /SQLSYSADMINACCOUNTS="BUILTIN\ADMINISTRATORS"
popd

Remove-Item -Recurse -Force "$temp\SQL-Express-2008-x64"
$exe="$target\MSSQL10.SQL2008RTM\MSSQL\Binn\sqlservr.exe"
& netsh firewall add allowedprogram `"$exe`" `"SQL Express 2008 x64`" ENABLE
