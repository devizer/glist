#!/usr/bin/env pwsh
# [string] Platform: "Windows", "Linux", "Darwin", "FreeBSD", "Unix (unknown)"
# [bool] IsCore
# [bool] IsWindows
function Get-CrossPlatformInfo()
{
  $info = @{
    IsCore = ($PSVersionTable.PSEdition -eq "Core");
    IsWindows = ("Win32NT" -eq [Environment]::OSVersion.Platform);
    IsNanoServer = $false;
    Platform = "Unknown";
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
  
  return $info;
}

Get-CrossPlatformInfo
