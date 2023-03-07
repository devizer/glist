rem powershell -File Install-SQL-2008-R2-SP2-x64.ps1
set url=https://raw.githubusercontent.com/devizer/glist/master/bin/sql-2008-R2-SP2-x86/Installer/Install-SQL-2008-R2-SP2-x86.ps1
set outfile=%AppData%\Temp\Install-SQL-2008-R2-SP2-x86.ps1
mkdir "%AppData%\Temp" 1>nul 2>&1
rem echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; for ($i=1; $i -le 3; $i++) { $d=new-object System.Net.WebClient; try { $d.DownloadFile("$Env:url","$Env:outfile"); exit 0; } catch { Write-Host $_; Write-Host "Try $i of 3 failed for $($Env:url)" -ForegroundColor DarkRed; } } Exit 1  | powershell -command -
type "%outfile%" | powershell -c -
