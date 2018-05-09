rem powershell -File Install-SQL-2008-R2-SP2-x64.ps1
set url=https://raw.githubusercontent.com/devizer/glist/master/bin/sql-2008-R2-SP2-x86/Installer/Install-SQL-2008-R2-SP2-x86.ps1
set outfile=%AppData%\Temp\Install-SQL-2008-R2-SP2-x86.ps1
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
type "%outfile%" | powershell -c -
