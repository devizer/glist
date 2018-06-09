Write-Host "Architecture: $($Env:PROCESSOR_ARCHITECTURE)"
$suffix="x86"; if ("$($Env:PROCESSOR_ARCHITECTURE)".ToUpper() -eq "AMD64") { $suffix="amd64"; }
$baseUrl="https://raw.githubusercontent.com/devizer/glist/master/bin/git/PortableGit-$suffix.7z.exe"
$download_path="$($Env:LocalAppData)"; if ($download_path -eq "") { $download_path="$($Env:UserProfile)"; }
$git_path="$download_path\PortableGit"
Write-Host "url: [$baseUrl]"
Write-Host "downloading portable git into path: $git_path"
New-Item $git_path -type directory -force -EA SilentlyContinue | out-null
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true};
$d=new-object System.Net.WebClient; $d.DownloadFile("$baseUrl","$download_path\PortableGit-$suffix.7z.exe");

$new_path = ";$download_path\PortableGit\bin;$download_path\PortableGit\cmd;$download_path\PortableGit\usr\bin"
$Env:PATH += $new_path

pushd $download_path
& cmd /c rd /q /s PortableGit | out-null 2>&1
& ".\PortableGit-$suffix.7z.exe" -y
ri "PortableGit-$suffix.7z.exe"
pushd PortableGit
& ".\post-install.bat"
popd
popd

& git --version

$prev_path=[Environment]::GetEnvironmentVariable("PATH", [EnvironmentVariableTarget]::User)
[Environment]::SetEnvironmentVariable("PATH", $prev_path + ";$new_path", [EnvironmentVariableTarget]::User)

