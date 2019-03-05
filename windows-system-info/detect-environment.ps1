#!/usr/bin/env pwsh
# [string] Platform: "Windows", "Linux", "Darwin", "FreeBSD", "Unix (unknown)"
# [bool] IsCore
# [bool] IsWindows
function Get-CrossPlatformInfo()
{
  $info = @{
    IsCore = ($PSVersionTable.PSEdition -eq "Core");
    IsWindows = ("Win32NT" -eq [Environment]::OSVersion.Platform);
    Platform = "Unknown";
    IsNanoServer = $false;
    IsMacOS = $false;
    IsRedHatDerivative = $false;
    IsDebianDerivative = $false;
    IsSuseDerivative = $false;
  }
  
  # Platform is one of: Windows | Linux | Darwin | FreeBSD | Unix (unknown)
  if ($info.IsWindows) { 
    $info.Platform = "Windows";
  } else { 
    $info.Platform = "Unix (unknown)"; 
    try { $info.Platform = ((uname -s) | out-string 2>$null).Trim(@([char] 13, [char] 10, [char]32)) }
    catch { $__="Posix is not preconfigured"; }
  }

  if ($info.IsWindows) {
    $installationType = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType;
    $info.IsNanoServer = $installationType -eq "Nano Server";
  }

  $info.IsMacOS = ($info.Platform -eq "Darwin");

  $info.IsLinux = ($info.Platform -eq "Linux");
  if ($info.IsLinux) {
    if (Test-Path "/etc/SuSE-release") { $info.IsSuseDerivative = $true; }
    if (Test-Path "/etc/debian_version") { $info.IsDebianDerivative = $true; }
    if (Test-Path "/etc/redhat-release") { $info.IsRedHatDerivative = $true; }
  }
  
  return $info;
}

Get-CrossPlatformInfo
