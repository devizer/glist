@echo off
set work=%USERPROFILE%\Temp\Fonts
mkdir "%work%" 1>nul 2>&1
for %%z in (Roboto Fira OpenSans liberation ubuntu-font-family Google-SuperFamilies) DO (
  set url=https://github.com/devizer/glist/raw/master/fonts/%%z.zip
  set outfile=%work%\%%z.zip
  echo Downloading "%%z" into [%work%\%%z]
  call :download
  echo Extracting %%z zip
  unzip -o "%work%\%%z.zip" -d "%work%\files"
)

:skip
for /r "%work%\files" %%f in (*.ttf) DO (
  xcopy /y "%%f" %windir%\Fonts\*
  RegisterFont.exe "%windir%\Fonts\%%~nf.ttf"
)
rem echo "Notify all the running apps about now fonts"
rem RegisterFont.exe ":broadcast"
echo "DONE. Finish. Bye"

goto exit;

:download
echo [System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}; $d=new-object System.Net.WebClient; $d.DownloadFile("$Env:url","$Env:outfile") | powershell -command -
exit /b


:exit
