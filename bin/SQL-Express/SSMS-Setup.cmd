call windows-version-vars-apply.cmd

set url=
set Params_New=/install /passive /norestart
set Params_Legacy=/ENU /QS /Action=Install /IACCEPTSQLSERVERLICENSETERMS /ENU /FEATURES=SSMS,Adv_SSMS

If Defined IS_WINDOWS_5_1_OR_ABOVE (If Defined IS_X86_WINDOWS (
  rem Ver 2008 R2 Express x64
  set url=https://download.microsoft.com/download/4/2/A/42A5A62F-9290-45CB-84CF-6A4E17888FDE/SQLManagementStudio_x86_ENU.exe
  set v=2008R2-Express-x86
  set params=%Params_Legacy%
  set Need_Extract=true
))

If Defined IS_WINDOWS_5_2_OR_ABOVE (If Defined IS_X64_WINDOWS (
  rem Ver 2008 R2 Express x86
  set url=https://download.microsoft.com/download/4/2/A/42A5A62F-9290-45CB-84CF-6A4E17888FDE/SQLManagementStudio_x64_ENU.exe
  set v=2008R2-Express-x64
  set params=%Params_Legacy%
  set Need_Extract=true
))

If Defined IS_WINDOWS_6_1_OR_ABOVE (If Defined IS_X86_WINDOWS (
  rem Ver 2014 12.0.2000.8
  set url=https://download.microsoft.com/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/MgmtStudio%%2032BIT/SQLManagementStudio_x86_ENU.exe
  set V=2014-x86
  set params=%Params_Legacy%
  set Need_Extract=true
))

If Defined IS_WINDOWS_6_1_OR_ABOVE (If Defined IS_X64_WINDOWS (
  rem Ver 16.5.3 
  set url=https://download.microsoft.com/download/9/3/3/933EA6DD-58C5-4B78-8BEC-2DF389C72BE0/SSMS-Setup-ENU.exe
  set v=2016
  set params=%Params_New%
  set Need_Extract=
))

If Defined IS_WINDOWS_6_2_OR_ABOVE (If Defined IS_X64_WINDOWS (
  rem Ver 17.9.1
  set url=https://download.microsoft.com/download/D/D/4/DD495084-ADA7-4827-ADD3-FC566EC05B90/SSMS-Setup-ENU.exe
  set v=2017
  set params=%Params_New%
  set Need_Extract=
))

:TEST
If Not Defined url (
  Echo SQL Server Management Studio 2016/2017 is not supported on this OS
  Exit
)

set KEY=SSMS-Setup-%v%
set outfile=%AppData%\Temp\%KEY%.exe
echo Downloading [%KEY%.exe]
echo From: [%url%]
mkdir "%AppData%\Temp" 1>nul 2>&1
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -

If Defined Need_Extract (
  Echo Expracting setup to "%AppData%\Temp\%KEY%-Files"
  "%outfile%" /q /x:"%AppData%\Temp\%KEY%-Files"
  "%AppData%\Temp\%KEY%-Files\Setup" %params%
) Else (
  "%outfile%" %params%
)

exit

SSMS Express 2008 R2: 
https://download.microsoft.com/download/4/2/A/42A5A62F-9290-45CB-84CF-6A4E17888FDE/SQLManagementStudio_x86_ENU.exe
https://download.microsoft.com/download/4/2/A/42A5A62F-9290-45CB-84CF-6A4E17888FDE/SQLManagementStudio_x64_ENU.exe
Command line is the same:
.\setup.exe /ENU /QS /Action=Install /IACCEPTSQLSERVERLICENSETERMS /ENU /FEATURES=SSMS,Adv_SSMS

