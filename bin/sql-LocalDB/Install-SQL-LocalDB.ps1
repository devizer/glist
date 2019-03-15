# One Line Installer
# @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/devizer/glist/master/bin/sql-LocalDB/Install-SQL-LocalDB.ps1'))"
function Download-Essentials {
  $files=$("Essentials.7z.exe")
  $baseUrl="https://raw.githubusercontent.com/devizer/glist/master/Essentials/"
  $Temp="$($Env:LocalAppData)"; if ($Temp -eq "") { $Temp="$($Env:UserProfile)"; }
  $Temp="$Temp\Temp"
  $Essentials="$Temp\Essentials"
  Write-Host "downloading essentials (7z, parallel-download) to the [$Essentials] folder"
  New-Item $Essentials -type directory -force -EA SilentlyContinue | out-null
  [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true};
  foreach($file in $files) {
    $d=new-object System.Net.WebClient; $d.DownloadFile("$baseurl/$file","$Essentials\$file");
  }
  pushd $Essentials
  $extract_log = (& .\Essentials.7z.exe -y 2>&1)
  ri Essentials.7z.exe -force -EA SilentlyContinue | out-null
  popd
  $isX64 = ("$($Env:PROCESSOR_ARCHITECTURE)" -eq "AMD64");
  If ($isX64) { $_7_Zip = "$Essentials\x64\7z.exe"; } Else { $_7_Zip="$Essentials\x86\7z.exe"; }
  Write-Host "Architecture: $($Env:PROCESSOR_ARCHITECTURE). 7-Zip: $_7_Zip";
  return @{
    IsX64 = $isX64;
    Temp = $Temp;
    Essentials = $Essentials;
    SevenZip = $_7_Zip;
    ParallelDownloader = "$Essentials\Parallel-Download.exe";
    Tee = "$Essentials\Tee.exe"
  }
}

$Essentials = Download-Essentials;

$download_To="$($Essentials.Temp)\LocalDB-Installer"
if ($essentials.IsX64) { $suffix="v14-x64"; } Else { $suffix="v12-x86"; }
$pars=@("`"$download_To`"", "https://raw.githubusercontent.com/devizer/glist/master/bin/sql-LocalDB/Sql-LocalDB-$suffix.msi")
pushd "$($Essentials.Temp)"
& "$($Essentials.ParallelDownloader)" $pars
popd

if (Get-Command Add-WindowsFeature -errorAction SilentlyContinue)
{
    Write-Host "Installing .NET 3.5 and 4.5"
    Add-WindowsFeature Net-Framework-Core -EA SilentlyContinue
    Add-WindowsFeature NET-Framework-45-Core -EA SilentlyContinue
}


Write-Host "Suspending .NET NGEN Queue"
pushd "$Env:windir\microsoft.net"
foreach($ngen in @("Framework64\v2.0.50727\ngen.exe", "Framework64\v4.0.30319\ngen.exe", "Framework\v2.0.50727\ngen.exe", "Framework\v4.0.30319\ngen.exe")) {
  if (Test-Path $ngen) { 
    $__ = (& $ngen queue pause 2>&1)
  }
}
popd

pushd "$download_To"
Write-Host "Installing SQL-LocalDB-$suffix.MSI ..."
cmd /c msiexec /i "SQL-LocalDB-$suffix.MSI" IACCEPTSQLLOCALDBLICENSETERMS=YES /qn /L*v SqlLocaLDB-$suffix.log
Write-Host "Log file is $download_To/SqlLocaLDB-$suffix.log"
popd

Remove-Item -Force "$download_To\*.MSI"
