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

function GetMsiExitCodeDescription {
  param([int] $exitCode)
  $descriptions = @(
    0, "The action completed successfully.",
    13, "The data is invalid.",
    87, "One of the parameters was invalid.",
    120, "This value is returned when a custom action attempts to call a function that cannot be called from custom actions. The function returns the value ERROR_CALL_NOT_IMPLEMENTED. Available beginning with Windows Installer version 3.0.",
    1259, "If Windows Installer determines a product may be incompatible with the current operating system, it displays a dialog box informing the user and asking whether to try to install anyway. This error code is returned if the user chooses not to try the installation.",
    1601, "The Windows Installer service could not be accessed. Contact your support personnel to verify that the Windows Installer service is properly registered.",
    1602, "The user cancels installation.",
    1603, "A fatal error occurred during installation.",
    1604, "Installation suspended, incomplete.",
    1605, "This action is only valid for products that are currently installed.",
    1606, "The feature identifier is not registered.",
    1607, "The component identifier is not registered.",
    1608, "This is an unknown property.",
    1609, "The handle is in an invalid state.",
    1610, "The configuration data for this product is corrupt. Contact your support personnel.",
    1611, "The component qualifier not present.",
    1612, "The installation source for this product is not available. Verify that the source exists and that you can access it.",
    1613, "This installation package cannot be installed by the Windows Installer service. You must install a Windows service pack that contains a newer version of the Windows Installer service.",
    1614, "The product is uninstalled.",
    1615, "The SQL query syntax is invalid or unsupported.",
    1616, "The record field does not exist.",
    1618, "Another installation is already in progress. Complete that installation before proceeding with this install. For information about the mutex, see MSIExecute Mutex.",
    1619, "This installation package could not be opened. Verify that the package exists and is accessible, or contact the application vendor to verify that this is a valid Windows Installer package.",
    1620, "This installation package could not be opened. Contact the application vendor to verify that this is a valid Windows Installer package.",
    1621, "There was an error starting the Windows Installer service user interface. Contact your support personnel.",
    1622, "There was an error opening installation log file. Verify that the specified log file location exists and is writable.",
    1623, "This language of this installation package is not supported by your system.",
    1624, "There was an error applying transforms. Verify that the specified transform paths are valid.",
    1625, "This installation is forbidden by system policy. Contact your system administrator.",
    1626, "The function could not be executed.",
    1627, "The function failed during execution.",
    1628, "An invalid or unknown table was specified.",
    1629, "The data supplied is the wrong type.",
    1630, "Data of this type is not supported.",
    1631, "The Windows Installer service failed to start. Contact your support personnel.",
    1632, "The Temp folder is either full or inaccessible. Verify that the Temp folder exists and that you can write to it.",
    1633, "This installation package is not supported on this platform. Contact your application vendor.",
    1634, "Component is not used on this machine.",
    1635, "This patch package could not be opened. Verify that the patch package exists and is accessible, or contact the application vendor to verify that this is a valid Windows Installer patch package.",
    1636, "This patch package could not be opened. Contact the application vendor to verify that this is a valid Windows Installer patch package.",
    1637, "This patch package cannot be processed by the Windows Installer service. You must install a Windows service pack that contains a newer version of the Windows Installer service.",
    1638, "Another version of this product is already installed. Installation of this version cannot continue. To configure or remove the existing version of this product, use Add/Remove Programs in Control Panel.",
    1639, "Invalid command line argument. Consult the Windows Installer SDK for detailed command-line help.",
    1640, "The current user is not permitted to perform installations from a client session of a server running the Terminal Server role service.",
    1641, "The installer has initiated a restart. This message is indicative of a success.",
    1642, "The installer cannot install the upgrade patch because the program being upgraded may be missing or the upgrade patch updates a different version of the program. Verify that the program to be upgraded exists on your computer and that you have the correct upgrade patch.",
    1643, "The patch package is not permitted by system policy.",
    1644, "One or more customizations are not permitted by system policy.",
    1645, "Windows Installer does not permit installation from a Remote Desktop Connection.",
    1646, "The patch package is not a removable patch package. Available beginning with Windows Installer version 3.0.",
    1647, "The patch is not applied to this product. Available beginning with Windows Installer version 3.0.",
    1648, "No valid sequence could be found for the set of patches. Available beginning with Windows Installer version 3.0.",
    1649, "Patch removal was disallowed by policy. Available beginning with Windows Installer version 3.0.",
    1650, "The XML patch data is invalid. Available beginning with Windows Installer version 3.0.",
    1651, "Administrative user failed to apply patch for a per-user managed or a per-machine application that is in advertise state. Available beginning with Windows Installer version 3.0.",
    1652, "Windows Installer is not accessible when the computer is in Safe Mode. Exit Safe Mode and try again or try using System Restore to return your computer to a previous state. Available beginning with Windows Installer version 4.0.",
    1653, "Could not perform a multiple-package transaction because rollback has been disabled. Multiple-Package Installations cannot run if rollback is disabled. Available beginning with Windows Installer version 4.5.",
    1654, "The app that you are trying to run is not supported on this version of Windows. A Windows Installer package, patch, or transform that has not been signed by Microsoft cannot be installed on an ARM computer.",
    3010, "A restart is required to complete the install. This message is indicative of a success. This does not include installs where the ForceReboot action is run."
  );
  for($i=0; $i -lt $descriptions.Length; $i=$i+2) {
    if ($exitCode -eq $descriptions[$i]) {
      return "[$exitCode] $($descriptions[$i+1])";
    }
  }
  return "$exitCode"
}

function ShowLocalDbVersion
{
    # Powershell 2.0 compatible
    try {
      $con = new-object System.Data.SqlClient.SqlConnection("Server=(localdb)\mssqllocaldb;Integrated Security=SSPI; Connection Timeout=9")
      $sql = "Select Cast(ServerProperty('Edition') as nvarchar) + ' ' + Cast(ServerProperty('ProductVersion') as nvarchar)"
      $cmd = new-object System.Data.SqlClient.SqlCommand($sql, $con)
      $con.Open()
      $rdr = $cmd.ExecuteReader()
      $__ = $rdr.Read()
      Write-Host "LocalDB Version: $($rdr.GetString(0))"
      $con.Close()
    } catch { 
      Write-Host "(localdb)\mssqllocaldb is not accessible $($_.Exception.GetType().Name) $($_.Exception.Message)"
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
$msiResult = $LASTEXITCODE;
Write-Host "MSI Result: $(GetMsiExitCodeDescription $msiResult)"
Write-Host "Log file is $download_To/SqlLocaLDB-$suffix.log"
popd

Remove-Item -Force "$download_To\*.MSI" -errorAction SilentlyContinue
ShowLocalDbVersion
