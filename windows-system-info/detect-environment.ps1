# [string] Platform: Windows, NanoServer, Linux, Darwin, FreeBSD, Unix (unknown)
# [bool] IsCore
# [bool] IsWindows
function Get-CrossPlatformInfo()
{
  $installationType = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType

  $info = @{
    IsCore = ($PSVersionTable.PSEdition -eq "Core");
    IsWindows = ("Win32NT" -eq [Environment]::OSVersion.Platform);
    IsNanoServer = ($installationType -eq "Nano Server");
    Platform = "Unknown";
  }
  # Platform is one of: Windows | Linux | Darwin | FreeBSD | Unix (unknown)
  if ($info.IsWindows) { 
    $info.Platform = "Windows" 
  } else { 
    $info.Platform = "Unix (unknown)"; 
    try { $info.Platform = ((uname -s) | out-string 2>$null).Trim(@([char] 13, [char] 10, [char]32)) }
    } catch {$__="Posix is not preconfigured";}
  }
  
  return $info;
}
Get-CrossPlatformInfo
# if ($PSVersionTable.PSEdition -eq "Core") { Write-Host "Core"; }