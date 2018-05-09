set archive=sql-express-all.7z.exe
set url=https://raw.githubusercontent.com/devizer/glist/master/bin/SQL-Express/windows-core/
set outdir=%AppData%\Temp\SQL-Express-All
set outfile=%outdir%\%archive%
mkdir "%outdir%" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
pushd "%outdir%"
"%archive%" -y
call all.cmd
popd
