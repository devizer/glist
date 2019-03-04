call windows-version-vars-apply.cmd

If Defined IS_WINDOWS_6_1_OR_ABOVE (
  rem Ver 16.5.3 
  set url=https://download.microsoft.com/download/9/3/3/933EA6DD-58C5-4B78-8BEC-2DF389C72BE0/SSMS-Setup-ENU.exe
  set v=2016
)
If Defined IS_WINDOWS_6_2_OR_ABOVE (
  rem Ver 17.9.1
  set url=https://download.microsoft.com/download/D/D/4/DD495084-ADA7-4827-ADD3-FC566EC05B90/SSMS-Setup-ENU.exe
  set v=2017
)

If Not Defined url (
  Echo SQL Server Management Studio 2016/2017 is not supported on this OS
  Exit
)

set KEY=SSMS-Setup-%v%
echo DOWNLOADING SSMS-Setup %v%
set outfile=%AppData%\Temp\%KEY%.exe
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
"%outfile%" /install /passive /norestart
