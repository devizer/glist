@echo off
set work=%USERPROFILE%\Temp\Fonts
mkdir "%work%" 1>nul 2>&1

for %%f in (RegisterFont.exe RegisterFont.exe.config unzip.exe) DO (
  set url=https://raw.githubusercontent.com/devizer/glist/master/fonts/on-windows/%%f
  set outfile=%work%\%%f
  echo Downloading "%%f" into [%work%\%%f]
  call :download
)


for %%z in (Roboto Fira OpenSans liberation ubuntu-font-family Google-SuperFamilies Barlow_Semi_Condensed) DO (
  set url=https://raw.githubusercontent.com/devizer/glist/master/fonts/%%z.zip
  set outfile=%work%\%%z.zip
  echo Downloading "%%z" into [%work%\%%z]
  call :download
  echo Extracting %%z zip
  "%work%\unzip.exe" -o "%work%\%%z.zip" -d "%work%\files"
)

:skip
for /r "%work%\files" %%f in (*.ttf) DO (
  xcopy /y "%%f" %windir%\Fonts\*
  "%work%\RegisterFont.exe" "%windir%\Fonts\%%~nf.ttf"
)
echo "Fonts are installed. Next we are notify all the running apps about new fonts. It may take a while."
time /t && "%work%\RegisterFont.exe" :broadcast && time /t
echo "DONE. Finish. Bye"

goto exit;

:download
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
exit /b


:exit
