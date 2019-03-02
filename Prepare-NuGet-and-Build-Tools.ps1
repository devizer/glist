$packages = @("vswhere", "ReportUnit",
  "NUnit.ConsoleRunner", "NUnit.Extension.NUnitV2Driver", "NUnit.Extension.NUnitV2ResultWriter", 
  "xunit.runner.console", "xunit",
  "JetBrains.dotCover.CommandLineTools");


if ($false) {
try { 
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
  Write-Host "TLS Client version is 1.2" -ForegroundColor DarkGreen
} catch { Host "TLS 1.2 is not supported" -ForegroundColor DarkRed }
}

# Arrange
$baseDir=$Env:LocalAppData; if (!$baseDir) { $baseDir=$Env:AppData; }
$workDir = "$baseDir\temp\build-tools-online.temp"
Write-Host "Build Tools Folder: $workDir" -ForegroundColor DarkGray
$packagesDir = "$workDir\packages"
New-Item -ItemType Directory -Path $packagesDir -EA SilentlyContinue | out-null
$color="Magenta"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $webClient=new-object System.Net.WebClient; 
$report_Cmd = "~local-build-tools.cmd"
[IO.File]::WriteAllText($report_Cmd, "@REM Local Build Tools. Auto-generated.`r`n");

function AddVar { param([string]$var, [string]$value)
  [IO.File]::AppendAllText($report_Cmd, "@set $var=$value`r`n");
  Write-Host "$var=$value" -ForegroundColor Green
  ${Env:$var}=$value
  # [Environment]::SetEnvironmentVariable($var, $value, "User")
}

function GetSHA1 { param( [string] $fileName )
  $sha1 = New-Object System.Security.Cryptography.SHA1CryptoServiceProvider 
  [System.BitConverter]::ToString( $sha1.ComputeHash([System.IO.File]::ReadAllBytes($fileName))).Replace("-","")
}

function SmartDownload { param([string] $key, [string] $url, [string] $fileName)
  $path = ""; if (Test-Path "$workdir\${key}.path") { $path = Get-Content "$workdir\${key}.path"; }
  $sha1 = ""; if (Test-Path "$workdir\${key}.sha1") { $sha1 = Get-Content "$workdir\${key}.sha1"; }
  if ($path -And (Test-Path $path) -And ($sha1 -eq (GetSHA1 $path))) { 
    Write-Host "$fileName already present: $path" -ForegroundColor DarkGray;
    return $path;
  }
  $path = "$workdir\$fileName";
  $dir = [System.IO.Path]::GetDirectoryName($path)
  Write-Host "Create DIR: $dir"
  New-Item -ItemType Directory -Path $dir -EA SilentlyContinue | out-null
  Write-Host "Caching '$url' as`r`n        [$path]" -ForegroundColor $color
  try {
    $webClient.DownloadFile($url, $path);
    $path > "$workdir\${key}.path"
    GetSHA1 $path > "$workdir\${key}.sha1"
    return $path
  } catch {
    Write-Host "Error downloading: $url" -ForeGroundColor DarkRed
    Write-Host "$($_.Exception)" -ForeGroundColor Red
    return $null
  }
}

function SmartDownloadSfx { param([string] $key, [string] $url, [string] $fileName)
  $sfx = SmartDownload $key $url $fileName
  Write-Host "SFX ${fileName}: $sfx" -ForegroundColor DarkGray
  $dir = [System.IO.Path]::GetDirectoryName($sfx)
  pushd $dir
  $output = (& $sfx -y) | Out-String 
  popd
  return $dir
}

# function SmartExtractUrl { param([string]$url, [string]$relPath, [string]$exe)

function SmartNugetInstall { param( [string] $package ) 
  $done=""; if (Test-Path "$packagesDir\$package.is-done") { $done = Get-Content "$packagesDir\$package.is-done"; }
  if (-Not $done) {
    pushd "$packagesDir"
    Write-Host  "Caching nuget package [$package]" -ForegroundColor $color
    & "$nuget" install $package >> ..\nuget.log 2>&1
    if ($LastExitCode -ne 0) {
      Write-Host "Unabale to install $package using nuget" -ForegroundColor Red
      popd; return;
    }
    "Shure" > "$workDir\packages\$package.is-done"
    popd
  }
  else {
    Write-Host "Package $package already cached" -ForegroundColor DarkGray;
  }  
  return "$workDir\packages"
}

# Download nuget.exe

$nuget_41 = SmartDownload "NuGet-4.1.0(cache)" "https://dist.nuget.org/win-x86-commandline/v4.1.0/nuget.exe" "NuGet-4.1.0.exe"
$nuget_344 = SmartDownload "NuGet-3.4.4(cache)" "https://dist.nuget.org/win-x86-commandline/v3.4.4/nuget.exe" "NuGet-3.4.4.exe"
$nuget_Latest = SmartDownload "NuGet-latest(cache)" "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" "NuGet-latest.exe"
$nuget_481 = SmartDownload "NuGet-4.8.1(cache)" "https://dist.nuget.org/win-x86-commandline/v4.8.1/nuget.exe" "NuGet-4.8.1.exe"
$nuget=$nuget_Latest
$nuget=$nuget_481

$nuget_latest_version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($nuget_Latest).FileVersion
Write-Host "NuGet (latest) version is: $nuget_latest_version" -ForegroundColor DarkGray





$essentials_dir = SmartDownloadSfx "Essentials(cache)" "https://raw.githubusercontent.com/devizer/glist/master/Essentials/Essentials.7z.exe" "Essentials\Essentials.7z.exe"

# Downloading packages
foreach ($p in $packages) { $p_Path = SmartNugetInstall $p; }

# VS 2017 and later
$vswhere = join-Path -Path "$packagesDir\vswhere*" -ChildPath "tools\vswhere.exe" -Resolve
if ($vswhere) { 
  Write-Host "vswhere: $vswhere" -ForegroundColor DarkGray
} else {
  Write-Host "Unable to find vswhere.exe. Check is internet connection works and support TLS/SSL" -ForegroundColor Red
}

AddVar "ESSENTIALS_PATH" $essentials_dir
AddVar "NUGET_EXE" $nuget
AddVar "VSWHERE_EXE" $vswhere

$vs_Dir = (& "$vswhere" -latest -products * -requires Microsoft.Component.MSBuild -property installationPath) | Out-String;
$vs_Dir = "$vs_Dir".Trim([char]10,[char]13)
AddVar "VS_PATH" "$vs_Dir"
if ($vs_Dir) { 
  $msbuild_x86 = join-Path -Path "$vs_Dir" -ChildPath "MSBuild\*\Bin\MSBuild.exe" -Resolve
  $msbuild_x64 = join-Path -Path "$vs_Dir" -ChildPath "\MSBuild\*\Bin\amd64\MSBuild.exe" -Resolve
}
if (-Not ("${Env:PROCESSOR_ARCHITECTURE}".ToUpper() -eq "AMD64")) { 
  $msbuild_x64 = $null;
}
$msbuild=$msbuild_x64; if (-Not $msbuild) { $msbuild=$msbuild_x86; }

AddVar "MSBUILD_EXE" $msbuild
AddVar "MSBUILD_x86_EXE" $msbuild_x86
AddVar "MSBUILD_x64_EXE" $msbuild_x64

$nunit_Runner = join-Path -Path "$packagesDir\NUnit.ConsoleRunner.*" -ChildPath "tools\nunit*-console.exe" -Resolve
AddVar "NUNIT_RUNNER_EXE" $nunit_Runner

$xunit_Runner = join-Path -Path "$packagesDir\xunit.runner.console.*" -ChildPath "tools\net47\xunit.console.exe" -Resolve
AddVar "XUNIT_RUNNER_EXE" $xunit_Runner

$report_Exe = join-Path -Path "$packagesDir\ReportUnit.*" -ChildPath "tools\ReportUnit*.exe" -Resolve
AddVar "REPORT_UNIT_EXE" $report_Exe

$dotCover_Exe = join-Path -Path "$packagesDir\JetBrains.dotCover.CommandLineTools.*" -ChildPath "tools\dotCover.exe" -Resolve
AddVar "DOTCOVER_EXE" $dotCover_Exe
