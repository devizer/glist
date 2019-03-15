# One Line Installer
# @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/devizer/glist/master/bin/sql-LocalDB/Install-SQL-LocalDB.ps1'))"
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

# $suffix="v13-x64"; if ( -Not ("$($Env:PROCESSOR_ARCHITECTURE)" -eq "AMD64")) { $suffix="v11-x86"; }
$suffix="v14-x64"; if ( -Not ("$($Env:PROCESSOR_ARCHITECTURE)" -eq "AMD64")) { $suffix="v12-x86"; }
$pars=@("`"$Temp\LocalDB-Installer`"", "https://raw.githubusercontent.com/devizer/glist/master/bin/sql-LocalDB/SQL-LocalDB-$suffix.msi")
pushd $Temp
& "$Essentials\Parallel-Download.exe" $pars
popd

Write-Host "Installing .NET 3.5 and 4.5"
Add-WindowsFeature Net-Framework-Core -EA SilentlyContinue
# Add-WindowsFeature NET-Framework-45-Core -EA SilentlyContinue
pushd "$Env:windir\microsoft.net"
& Framework64\v2.0.50727\ngen.exe  queue pause
& Framework64\v4.0.30319\ngen.exe  queue pause
& Framework\v2.0.50727\ngen.exe    queue pause
& Framework\v4.0.30319\ngen.exe    queue pause
popd

pushd "$temp\LocalDB-Installer"
Write-Host "Installing SQL-LocalDB-$suffix.MSI ..."
cmd /c msiexec /i "SQL-LocalDB-$suffix.MSI" IACCEPTSQLLOCALDBLICENSETERMS=YES /qn /L*v SqlLocaLDB-$suffix.log
popd

Remove-Item -Force "$temp\LocalDB-Installer\*.MSI"
