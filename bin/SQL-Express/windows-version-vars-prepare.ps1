function AddVar { param([string]$var, [string]$value)
  [IO.File]::AppendAllText($report_Cmd, "@set $var=$value`r`n");
  Write-Host "$var=$value" -ForegroundColor Green
  ${Env:$var}=$value
}

function BoolAsValue { param([bool]$bool)
  if ($bool) { "true"; } else { "" };
}

$todo = @(
  @{ Major = 5; Minor = 0 }, # 2000
  @{ Major = 5; Minor = 1 }, # XP x86
  @{ Major = 5; Minor = 2 }, # XP x64, Server 2003
  @{ Major = 6; Minor = 0 }, # Vista, Server 2008
  @{ Major = 6; Minor = 1 }, # 7, Server 2008 R2
  @{ Major = 6; Minor = 2 }, # 8, Server 2012
  @{ Major = 6; Minor = 3 }, # 8.1, Server 2012 R2
  @{ Major =10; Minor = 0 }  # 10, Server 2016, Nano Server
);
$major = [System.Environment]::OSVersion.Version.Major;
$minor = [System.Environment]::OSVersion.Version.Minor;

$report_Cmd = "~windows-version-vars.cmd";
$report_Cmd = $Env:windows_version_intermediate_file
try { $__=[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($report_Cmd)); } catch {}
[IO.File]::WriteAllText($report_Cmd, "@Echo Applying windows version vars using [$report_Cmd].`r`n");

foreach($check in $todo) {
  $var = "IS_WINDOWS_$($check.Major)_$($check.Minor)_OR_ABOVE";
  $isItOrAbove = ($major -gt $check.Major) -or ( ($major -eq $check.Major) -and ($minor -ge $check.Minor) )
  if ($isItOrAbove) { $value="true" } else { $value = "" };
  AddVar $var $value
}

$is64 = (Get-WMIObject Win32_ComputerSystem).SystemType.IndexOf("64") -ge 0;
if ($is64) { $v86=""; $v64="true"; } else { $v86="true"; $v64=""; }
AddVar "IS_X86_WINDOWS" $v86
AddVar "IS_X64_WINDOWS" $v64

$win_10_release_id = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ReleaseId
AddVar "WINDOWS_10_RELEASE_ID" $win_10_release_id

$installationType = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').InstallationType
AddVar "IS_NANO_SERVER" (BoolAsValue ($installationType -eq "Nano Server"))

$productType=""
$productTypeRaw = (Get-WMIObject Win32_OperatingSystem).ProductType
AddVar "IS_WINDOWS_SERVER" (BoolAsValue (-not ($productTypeRaw -eq 1)))
AddVar "IS_WINDOWS_WORKSTATION" (BoolAsValue ($productTypeRaw -eq 1))
AddVar "IS_DOMAIN_CONTROLLER" (BoolAsValue ($productTypeRaw -eq 2))


"DONE: [$($report_Cmd)] was updated."
