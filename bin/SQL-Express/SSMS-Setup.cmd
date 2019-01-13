set KEY=SSMS-Setup
echo DOWNLOADING SSMS-Setup
rem 16.5.1 for x86: https://download.microsoft.com/download/9/3/3/933EA6DD-58C5-4B78-8BEC-2DF389C72BE0/SSMS-Setup-ENU.exe
set url=https://download.microsoft.com/download/0/D/2/0D26856F-E602-4FB6-8F12-43D2559BDFE4/SSMS-Setup-ENU.exe
rem Ver 17.9.1
set url=https://download.microsoft.com/download/D/D/4/DD495084-ADA7-4827-ADD3-FC566EC05B90/SSMS-Setup-ENU.exe
set outfile=%AppData%\Temp\%KEY%.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -

"%outfile%" /install /passive /norestart
