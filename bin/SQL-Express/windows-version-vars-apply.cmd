@echo off
pushd "%~dp0"
set _work_dir=%CD%
rem echo Work Dir: %_work_dir%
popd

set windows_version_intermediate_file=%APPDATA%\temp\~windows-version-vars-%RANDOM%.cmd
type "%_work_dir%\windows-version-vars-prepare.ps1" | powershell -command -
call "%windows_version_intermediate_file%"
del "%windows_version_intermediate_file%" >nul 2>&1
