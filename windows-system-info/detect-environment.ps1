function GetCrossPlatformInfo()
{
  $info = @{
    IsDesktop = -not ($PSVersionTable.PSEdition -eq "Core");
    IsWindows = ("Win32NT" -eq [Environment]::OSVersion.Platform);
    IsNanoServer = ((get-command "Get-ComputerInfo" -errorAction SilentlyContinue) -and ("Nano Server" -eq ((get-computerinfo -Property WindowsInstallationType).WindowsInstallationType)));
  }
  # Platform is one of: Windows | Linux | Darwin | FreeBSD | Unix (unknown)
  if ($info.IsWindows) { $info.Platform = "Windows" } else { $info.Platform = "Unix (unknown)"; try { $info.Platform = ((uname -s) | out-string 2>$null).Trim(@([char] 13, [char] 10, [char]32)) } catch {} }

  $ret = @{
     Kind="Desktop"; 
     IsCore=$false; 
     Description="Classic powershell on Windows XP ... Server 2019+ including Server Core)";
     Platform=$info.Platform;
  };
  
  if ($PSVersionTable.PSEdition -eq "Core") { 
    $ret = @{Kind=$null; IsCore=$true; Description=$null};
    # Either pwsh or Nano Server.
    # First, check nano server
    if (get-command "Get-ComputerInfo" -errorAction SilentlyContinue) {
      if ("Nano Server" -eq ((get-computerinfo -Property WindowsInstallationType).WindowsInstallationType)) { 
        $ret.Kind = "Nano"; 
        $ret.Description = "Nano Server"
      }
    }
    if ($ret.Kind -eq $null) { 
      # pwsh on either Windows or Unix
      if ("Win32NT" -eq [Environment]::OSVersion.Platform) {
        $ret.Kind="Windows-Core";
        $ret.Description="pwsh core on Windows, but not a Nano Server"
      }
      else
      {
        $ret.Kind="Unix-Core";
        $ret.Description="pwsh core on Unix (either Linux or MacOS)"
      }
    }
  }
  return $ret;
}
GetCrossPlatformInfo
# if ($PSVersionTable.PSEdition -eq "Core") { Write-Host "Core"; }