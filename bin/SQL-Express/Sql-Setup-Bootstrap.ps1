# Env Variables: SQL_SETUP_LOG_FOLDER
$Sql_Servers_Definition = @(
  @{  Title = "SQL SERVER 2019 RC (Developer)";
      Keys = @("Developer", "2019", "SqlServer", "Pre", "x64");
      Script = ".\SQL-2019-Pre.cmd"
   },
  @{  Title = "SQL SERVER 2017 (Developer)";
      Keys = @("Developer", "2017", "SqlServer", "Latest", "x64");
      Script = 'powershell -f .\sql-dev-2017.ps1'
   },
  @{  Title = "SQL SERVER 2017 (Express)";
      Keys = @("Express", "2017", "SqlServer", "x64");
      Script = ".\SQL-Express-2017-Updated.cmd"
   },
  @{  Title = "SQL SERVER 2016 (Express)";
      Keys = @("Express", "2016", "SqlServer", "x64");
      Script = ".\SQL-Express-2016-Updated.cmd"
   },
  @{  Title = "SQL SERVER 2014 SP2 x86 (Express)";
      Keys = @("Express", "2014", "SqlServer", "x86");
      Script = ".\SQL-Express-2014-SP2-x86.cmd"
   },
  @{  Title = "SQL SERVER 2012 SP3 (Express)";
      Keys = @("Express", "2012", "SqlServer", "x86", "x64");
      Script = ".\SQL-Express-2012-SP3.cmd"
   },
  @{  Title = "SQL SERVER 2008 R2 SP2 x86 (Express)";
      Keys = @("Express", "2008R2", "SqlServer", "x86");
      Script = ".\SQL-Express-2008-R2-SP2-x86.cmd"
   },
  @{  Title = "SQL SERVER 2008 SP3 (Express)";
      Keys = @("Express", "2008", "SqlServer", "x86", "x64");
      Script = ".\SQL-Express-2008-SP3-x64.cmd"
   },
  @{  Title = "SQL SERVER 2005 SP4 x86 (Express)"; 
      Keys = @("Express", "2005", "SqlServer", "x86");
      Script = '.\SQL-Express-2005-SP4-x86.cmd; @(${Env:ProgramFiles(x86)}, $Env:ProgramFiles) | % { $log_dir="$($_)\Microsoft SQL Server\90\Setup Bootstrap\LOG"; if (Test-Path $log_dir) { Write-Host "Store $log_dir as [Sql 2005 SP4 Setup Log.7z]"; & 7z a -t7z -mx=3 "$($Env:SQL_SETUP_LOG_FOLDER)\Sql 2005 SP4 Setup Log.7z" "$log_dir" *> "$Env:TEMP\_" } }'
      Comment = "Only for 2 AppVoyer images: Visual Studio 2017 & 2019 (the setup does not work on AppVoyer VS 2013 & 2015)"
   },
  @{  Title = "SQL SERVER LocalDB 2017"; LocalDB = $true;
      Keys = @("LocalDB", "2017", "Latest", "x64");
      Script = 'powershell -f .\Install-SQL-LocalDB.ps1; cp "$($Env:USERPROFILE)\AppData\Local\Temp\LocalDB-Installer\SqlLocaLDB-v14-x64.log" "$($Env:SQL_SETUP_LOG_FOLDER)";'
      Comment = "Actual Version is 2014 on the AppVeyor VS 2015 image. For x86 Windows it installs LocalDB 2014"
   },
  @{  Title = "SQL SERVER LocalDB 2016 SP1 CU8"; LocalDB = $true;
      Keys = ("LocalDB", "2016", "x64");
      Comment = "Actual Version is 2014 on the AppVeyor VS 2015 image"
   }
)

    function Say { param( [string] $message )
        Write-Host "$(Get-Elapsed) " -NoNewline -ForegroundColor Magenta
        Write-Host "$message" -ForegroundColor Yellow
    }
    
    function Get-Elapsed
    {
        if ($Global:startAt -eq $null) { $Global:startAt = [System.Diagnostics.Stopwatch]::StartNew(); }
        [System.String]::Concat("[", (new-object System.DateTime(0)).AddMilliseconds($Global:startAt.ElapsedMilliseconds).ToString("mm:ss"), "]");
    }; Get-Elapsed | out-null;

    # Display OS and CPU
    $currentVersion=Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $win_10_release_id = $currentVersion.ReleaseId; if (! $win_10_release_id) { $win_10_release_id = $currentVersion.CurrentBuildNumber }
    $win_name = $(Get-WMIObject win32_operatingsystem -EA SilentlyContinue).Caption
    Say "$($win_name): Release [$win_10_release_id], powershell [$($PSVersionTable.PSVersion)]"
    $cpu=Get-WmiObject Win32_Processor; Say "CPU: $($cpu.Name), $([System.Environment]::ProcessorCount) Cores";

    function Download-Installers {
        if (!$Global:SQL_SETUP_WORK) {
            $Work="$($Env:LocalAppData)"; if ($Work -eq "") { $Work="$($Env:UserProfile)"; }; $Work="$Work\Temp\Sql-Installers"
            if (-not (Test-Path $Work)) { New-Item -ItemType Directory -Path $Work -EA SilentlyContinue | out-null }
            Say "Downloading SQL Installer Scripts to: $Work"
            (new-object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/devizer/glist/master/bin/SQL-Express/windows-core/sql-express-all.7z.exe', "$Work\sql-express-all.7z.exe")
            pushd $Work
            & .\sql-express-all.7z.exe -y | out-null
            popd
            $Global:SQL_SETUP_WORK = $work
        }
    }

    function Install-SqlServer { param($description)
        Download-Installers
        # Say "Arg for (Install-SqlServer ...):"; $description | fl *
        if ($description.Script) {
            $instanceNameInfo=" as '$($description.InstanceName)' instance"; if (! "$($description.InstanceName)") {$instanceNameInfo=""}
            Say "Installing the '$($description.Title)'$instanceNameInfo"
            $Env:NEW_SQL_INSTANCE_NAME=$description.InstanceName
            pushd $Global:SQL_SETUP_WORK
            Invoke-Expression $description.Script *> "$($Env:SQL_SETUP_LOG_FOLDER)\Setup $($description.Title).log"
            popd
        } 
        
        # hide pre-installed LocalDB for tests with SQL Express/Developer
        if ($false -and $description.LocalDB -eq $null) {
            Say "Pre-installed SqlLocalDB.exe: $(Find-SqlLocalDB-Exe)"
            # it is imposible to delete LocalDB 2016, but it is ok to delete 2014th LocalDB
            # @(2016, 2014, 2016, 2016) | % { Uninstall-SqlLocalDB "$_" }
            Hide-LocalDB-Servers
        }
    }

    function Find-SqlServers-ByTags { param( [array] $keys )
       # Say "Args for (Find-SqlServers ...): $keys"
       if (!"$keys") { Say "WARNING! Empty tag list means NoSQL. Lol. [$keys]"; return; }
       $found=0;
       $Sql_Servers_Definition | % { $sql = $_
            $isIt=$true; foreach($k in $keys) { if (-not ($sql.Keys -contains $k)) { $isIt=$false; } }
            if ($isIt) { $sql; $found++ }
       }
       if (!$found) {Say "WARNING! Unknown SQL Server for tags: [$keys]"}
    }

    function Parse-SqlServers { param( [string] $list)
        Say "Installing SQL Server(s) by tags: $list"
        "$list".Split(@([char]44, [char]59)) | % { $sqlDef=$_.Trim()
            $arr = $sqlDef.Split(@([char]58));
            $sqlKey = $arr[0];
            if ($arr.Length -gt 1) { $instanceName=$arr[1].Trim(); } else {  $instanceName=$null; }
            $tags=@("$sqlKey".Split([char]32) | % {$_.Trim()} | where { $_.Length -gt 0 } )
            if ($tags.Count -gt 0) {
                Find-SqlServers-ByTags $tags | Select -First 1 | foreach { $_["InstanceName"] = $instanceName; $_ }
            }
        }
    }

    
    # returns array of strings like SQL2017, SQL2016, ...
    function Get-Preinstalled-SqlServers
    {
        $names = @();
        foreach($path in @('HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server')) {
            try { $v = (get-itemproperty $path).InstalledInstances; $names += $v } catch {}
        }
        $names | sort | where { "$_".Length -gt 0 }
    }

    function Disable-SqlServers { param( [array] $names ) 
        foreach($sqlname in $names) {
            Say "Disable MSSQL`$$sqlname"
            Stop-Service "MSSQL`$$sqlname" -ErrorAction SilentlyContinue
            Set-Service "MSSQL`$$sqlname" -StartupType Disabled
        }
    }

    function Delete-SqlServers { param( [array] $names ) 
        foreach($sqlname in $names) {
            Say "Delete MSSQL`$$sqlname"
            Stop-Service "MSSQL`$$sqlname" -EA SilentlyContinue
            Set-Service "MSSQL`$$sqlname" -StartupType Disabled
            & cmd /c sc delete "MSSQL`$$sqlname"
        }
    }

    # uninstallation does not work properly, but upgrade works better
    function Hide-LocalDB-Servers {
        Say "Hide SQL Server LocalDB"; 
        $path="HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server Local DB\Installed Versions"
        if (Test-Path $path) { Remove-Item -Path $path -Recurse -Force }
    }

    # return empty string if SqlLocalDB.exe is not found. always returns latest installed SqlLocalDB.exe
    function Find-SqlLocalDB-Exe {
        if ($Global:LocalDbExe -eq $null) {
            $Global:LocalDbExe=(Get-ChildItem -Path "C:\Program Files\Microsoft SQL Server" -Filter "SqlLocalDB.exe" -Recurse -ErrorAction SilentlyContinue -Force | Sort-Object -Property "FullName" -Descending)[0].FullName
            if ($Global:LocalDbExe) { Write-Host "$(Get-Elapsed) Found SqlLocalDB.exe full path: [$($Global:LocalDbExe)]" } else { Write-Host "$(Get-Elapsed) SqlLocalDB.exe NOT Found" }
        }
        "$($Global:LocalDbExe)"
    }

    # Does not work propery without reboot - logs report that unsunstall is successful, but
    function Uninstall-SqlLocalDB { param([string] $version)
        Say "Deleting LocalDB $version"
        $apps = Find-Apps "LocalDB" | ? { $($_.DisplayName -like "*$($version)*") -and ($_.DisplayName -like "*Microsoft*")  }
        if ($apps -and $apps[0]) { 
            # DisplayName, DisplayVersion, PSPath, PSChildName, UninstallString, Guid, MsiUninstallArgs
            $msi=@($apps)[0]; $msi_args=$msi.MsiUninstallArgs + " /L*v `"$($Env:ARTIFACT)\Uninstall $($msi.DisplayName).log`""
            Say "Deleting MSI Package $($msi.DisplayName) (version [$($msi.DisplayVersion)]) using args: [$msi_args]"
            start-process "msiexec.exe" -arg $msi_args -Wait
        } else {
            Say "LocalDB $version is not found"
        }
    }

    # https://stackoverflow.com/questions/113542/how-can-i-uninstall-an-application-using-powershell
    function Find-Apps { param([string] $pattern)
        $apps = @();
        $path32="HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        $path64="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
        foreach($path in @($path64, $path32)) {
            $u = gci $path | foreach { gp $_.PSPath } | ? { $_ -like "*$($pattern)*" }
            if ($u.Length -gt 0) { $apps += $u }
        }
        $apps |
            foreach { $_ | Add-Member Guid $_.PSChildName; $_ } |
            where { $_.PSobject.Properties.Name -match "DisplayName" } |
            where { "DisplayName" -in $_.PSobject.Properties.Name } |
            foreach { $_.DisplayName = "$($_.DisplayName)".Trim(); $_ } |
            foreach { $_ | Add-Member MsiUninstallArgs ("/X " + ($_.UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X","" ).ToString().Trim() + " /qn"); $_ } |
            sort @{e={$_.DisplayName}; a=$true}
    }

    function Show-SqlServers {
        get-wmiobject win32_service | where {$_.Name.ToLower().IndexOf("sql") -ge 0 } | sort-object -Property "DisplayName" | ft State, Name, DisplayName, StartMode, StartName
    }

    function Upgrade-PSReadLine { param([bool] $force)
       if ($force -or ($Env:APPVEYOR_BUILD_WORKER_IMAGE -eq "Visual Studio 2019")) {
           try {
               Say "Upgrading PSReadLine on '$($Env:APPVEYOR_BUILD_WORKER_IMAGE)' image"
               Install-Module PSReadLine -AllowPrerelease -Force
               Say "PSReadLine Upgraded"
           } catch {
               Say "PSReadLine Upgrade Failed. $($_.Exception.GetType().Name) $($_.Exception.Message)"
           }
       }
    }


if ($Env:SQL_SETUP_BOOTSTRAP_TEST) {
    $Sql_Servers_Definition | % { $_ | ft }
    $testCases = @(
      @{ Args = @("SqlServer", "2019");               Expected="SQL SERVER 2019 RC (Developer)"},
      @{ Args = @("SqlServer", "2017", "Developer");  Expected="SQL SERVER 2017 (Developer)" },
      @{ Args = @("SqlServer", "2017", "Express");    Expected="SQL SERVER 2017 (Express)" },
      @{ Args = @("SqlServer", "2016", "Express");    Expected="SQL SERVER 2016 (Express)" },
      @{ Args = @("SqlServer", "2014", "Express");    Expected="SQL SERVER 2014 SP2 x86 (Express)" },
      @{ Args = @("SqlServer", "2012", "Express");    Expected="SQL SERVER 2012 SP3 (Express)" },
      @{ Args = @("SqlServer", "2008R2", "Express");  Expected="SQL SERVER 2008 R2 SP2 x86 (Express)" },
      @{ Args = @("SqlServer", "2008", "Express");    Expected="SQL SERVER 2008 SP3 (Express)" },
      @{ Args = @("SqlServer", "2005", "Express");    Expected="SQL SERVER 2005 SP4 x86 (Express)" },
      @{ Args = @("SqlServer");                       Expected="SQL SERVER 2019 RC (Developer)" },
      @{ Args = @("LocalDB", "2017");                 Expected="SQL SERVER LocalDB 2017" },
      @{ Args = @("LocalDB", "2016");                 Expected="SQL SERVER LocalDB 2016 SP1 CU8" }
      @{ Args = @("LocalDB");                         Expected="SQL SERVER LocalDB 2017" },
      @{ Args = @("No Such SQL Server");              Expected=""; }
    )

    $errors = 0;
    $testCases | % { 
        $actual=(Find-SqlServers-ByTags $_.Args | Select -First 1).Title
        Write-Host "Test. For [$($_.Args)] Actual: [$actual], expected: [$($_.Expected)]"
        if ("$actual" -ne "$($_.Expected)") { Write-Host "Test Failed" -ForegroundColor Red; $errors++}
    }
    Write-Host "Total Errors: $errors";
    if ($errors) { Throw "Total Errors: $errors" }

    # Full Featured Example
    # Warning: Without reboot the SQL 2005 SP4 Express cant be installed if SQL 2019 is installed first
    Parse-SqlServers "SqlServer 2019 Developer: DEVELOPER_2019, SqlServer 2017 Developer: DEVELOPER_2017, SqlServer 2017 Express: EXPRESS_2017, SqlServer 2016: EXPRESS_2016, SqlServer 2014: EXPRESS_2014, SqlServer 2012: EXPRESS_2012, SqlServer 2008R2: EXPRESS_2008_R2, SqlServer 2008: Express_2008, SqlServer 2005: EXPRESS_2005, LocalDB 2017, LocalDB 2016"
}

# Find-SqlServers-ByTags SqlServer, 2019, Developer | % { $_.Title }
Download-Installers

# Example
# Parse-SqlServers "SqlServer 2019 Developer: DEVELOPER_2019, SqlServer 2017 Developer: DEVELOPER_2017, SqlServer 2017 Express: EXPRESS_2017, SqlServer 2016: EXPRESS_2016, SqlServer 2014: EXPRESS_2014, SqlServer 2012: EXPRESS_2012, SqlServer 2008R2: EXPRESS_2008_R2, SqlServer 2008: Express_2008, SqlServer 2005: EXPRESS_2005" | % { Install-SqlServer $_ }
