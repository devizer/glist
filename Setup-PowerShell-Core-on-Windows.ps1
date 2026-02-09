# Run-Remote-Script https://raw.githubusercontent.com/devizer/glist/master/Setup-PowerShell-Core-on-Windows.ps1 -Version 7.4.13 -InstallTo "C:\Apps\PowerShell.Core"
param($version="7.4.13", $installTo="$($Env:SystemDrive)\Apps\PowerShell.Core")

# TODO: ARCHITECTURE

$arch_suffix=Get-CPU-Architecture-Suffix-for-Windows

$url="https://github.com/PowerShell/PowerShell/releases/download/v$($version)/PowerShell-$($version)-win-$($arch_suffix).zip"
$file="PowerShell-$($version)-win-$($arch_suffix).zip"

pushd "$ENV:USERPROFILE"
Download-File-Managed "$url" ".\$file"
Extract-Archive-by-Default-Full-7z ".\$file" "$installTo"
Remove-Item -Path ".\$file" -Force -EA SilentlyContinue
pushd 

Add-Folder-To-System-Path $installTo
