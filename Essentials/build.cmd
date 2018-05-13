pushd ..\Parallel-Download
%WinDir%\Microsoft.NET\Framework64\v4.0.30319\msbuild /t:Rebuild /p:Consfiguration=Debug
xcopy /y bin\Debug\*.* ..\Essentials\*.*
popd

@del Essentials.7z 1>nul 2>nul
x86\7z a -t7z -mx=9 -sfx7zCon.sfx -mfb=128 -md=128m -ms=on -xr!Essentials.7z.exe Essentials.7z.exe
rem copy /b C:\Apps\7-Zip-x86\7zCon.sfx + Essentials.7z Essentials.7z.exe
@del Essentials.7z 1>nul 2>nul
del Parallel-Download.*