set archive=sql-express-all.7z.exe
set url=https://raw.githubusercontent.com/devizer/glist/master/bin/SQL-Express/windows-core/%archive%
set outdir=%AppData%\Temp\SQL-Express-All
If Defined LOCALAPPDATA (
  set outdir=%LOCALAPPDATA%\Temp\SQL-Express-All
)
set outfile=%outdir%\%archive%
mkdir "%outdir%" 1>nul 2>&1
rem echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; for ($i=1; $i -le 3; $i++) { $d=new-object System.Net.WebClient; try { $d.DownloadFile("$Env:url","$Env:outfile"); exit 0; } catch { Write-Host $_; Write-Host "Try $i of 3 failed for $($Env:url)" -ForegroundColor DarkRed; } } Exit 1  | powershell -command -

pushd "%outdir%"
"%archive%" -y
call all.cmd
popd
