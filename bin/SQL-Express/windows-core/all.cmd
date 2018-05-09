set url=https://raw.githubusercontent.com/devizer/glist/master/bin/SQL-Express/windows-core/sql-express-all.zip
set outfile=%AppData%\Temp\SQL-Express-All\sql-express-all.zip
set outdir=%AppData%\Temp\SQL-Express-All
mkdir "%AppData%\Temp\SQL-Express-All" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
echo [System.IO.Compression.ZipFile]::ExtractToDirectory("$Env:outfile", "$Env:outfile") | powershell -command -