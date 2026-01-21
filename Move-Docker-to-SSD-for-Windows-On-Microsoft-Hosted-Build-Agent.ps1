# Here is one line installer 
# Run-Remote-Script https://raw.githubusercontent.com/devizer/glist/master/Move-Docker-to-SSD-for-Windows-On-Microsoft-Hosted-Build-Agent.ps1

        # $old_dir = "$(& docker info --format "{{.DockerRootDir}}")"
        # Write-Line "Docker Existing Storage " -TextGreen "[$old_dir]"

        Select-WMI-Objects Win32_LogicalDisk | ?{ @(2, 3) -contains $_.DriveType } | 
              ? { $_.FreeSpace -or $_.Size } | 
              % { [pscustomobject] @{"Free (GB)" = [Math]::Round($_.FreeSpace / 1024/1024/1024.0,2); "Size (GB)" = [Math]::Round($_.Size/1024/1024/1024.0, 2); "  Mount"="   $($_.DeviceId)" ; "  Name"="   $($_.VolumeName)" }} |
              ft -autosize | Out-String -Width 1234

        if (Test-Path "D:\") {
           $new_data_root = "D:\Docker-Data"
           Write-Line -TextYellow "Upgrading Docker for maximum performance data-root = $($new_data_root)"

           $jsonFile="C:\ProgramData\Docker\config\daemon.json"
           if (Test-Path $jsonFile) { 
             Write-Host "Docker configuration exists: [$jsonFile]"
             cat $jsonFile
           } Else { 
             Write-Host "Docker configuration is MISSING: [$jsonFile]"
             New-Item -Path "C:\ProgramData\Docker\config" -ItemType Directory -Force -EA SilentlyContinue | Out-Null
             [System.IO.File]::WriteAllText($jsonFile, "{}", (New-Object System.Text.UTF8Encoding($false)))
           }

           $config = Get-Content -Raw -Path $jsonFile | ConvertFrom-Json
           $config | Add-Member -MemberType NoteProperty -Name "data-root" -Value $new_data_root -Force
           $new_json = $config | ConvertTo-Json -Depth 10
           [System.IO.File]::WriteAllText($jsonFile, $new_json, (New-Object System.Text.UTF8Encoding($false)))

           Write-Host "Docker configuration successflly updated [$jsonFile]"
           cat $jsonFile

           Write-Line -TextGreen "Restarting docker"
           restart-service docker
           Write-Line -TextGreen "Status of Docker Service"
           get-service docker | ft -autosize
        } Else {
          Write-Line -TextMagenta "Skipping Update of Docker Configuration. Missing Volume D:\"
        }

