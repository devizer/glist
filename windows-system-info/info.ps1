Write-Host 'group-header: Processor'
Get-WmiObject -Class Win32_Processor | Format-List Name,L2CacheSize,L3CacheSize,MaxClockSpeed
Write-Host 'group-header: ComputerSystem'
Get-WmiObject -Class Win32_ComputerSystem | Format-List Manufacturer,Model,TotalPhysicalMemory
Write-Host 'group-header: OperatingSystem'
Get-WmiObject -Class Win32_OperatingSystem | Format-List Caption,Version,ServicePackMajorVersion,ServicePackMinorVersion,OSArchitecture,TotalVirtualMemorySize,TotalVisibleMemorySize,FreePhysicalMemory,FreeVirtualMemory,FreeSpaceInPagingFiles,SystemDrive,SystemDirectory

