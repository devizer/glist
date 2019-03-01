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


# Done: Essentials

$pars=@("`"$Temp`"", "https://raw.githubusercontent.com/devizer/glist/master/bin/sql-2005-SP4-x86/SQL-Express-2005-SP4-x86.7z.exe")
pushd $Temp
& "$Essentials\Parallel-Download.exe" $pars
& $_7_Zip @("x", "-y", "SQL-Express-2005-SP4-x86.7z.exe")
ri SQL-Express-2005-SP4-x86.7z*
popd

Write-Host "Installing .NET 3.5 and 4.5. Perfimissions are required"
Add-WindowsFeature Net-Framework-Core -EA SilentlyContinue
Add-WindowsFeature NET-Framework-45-Core -EA SilentlyContinue
Install-WindowsFeature Net-Framework-Core -EA SilentlyContinue
Install-WindowsFeature NET-Framework-45-Core -EA SilentlyContinue

pushd $Env:windir\microsoft.net
& Framework64\v2.0.50727\ngen.exe  queue pause
& Framework64\v4.0.30319\ngen.exe  queue pause
& Framework\v2.0.50727\ngen.exe    queue pause
& Framework\v4.0.30319\ngen.exe    queue pause
popd

$target="${Env:SystemDrive}\SQL"
pushd "$temp\SQL-Express-2005-SP4-x86"
cmd /c .\setup.exe /qb ADDLOCAL=SQL_Engine INSTANCENAME=SQL_2005_SP4_X86 DISABLENETWORKPROTOCOLS=0 SECURITYMODE=SQL SAPWD=``1qazxsw2 INSTALLSQLDIR="$target" 
popd

Remove-Item -Recurse -Force "$temp\SQL-Express-2005-SP4-x86"
$exe="$target\MSSQL.1\MSSQL\Binn\sqlservr.exe"
& netsh firewall add allowedprogram `"$exe`" `"SQL Express 2005 SP4 x86`" ENABLE
