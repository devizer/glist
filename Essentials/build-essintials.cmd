pushd ..\Parallel-Download
%WinDir%\Microsoft.NET\Framework64\v4.0.30319\msbuild /t:Rebuild /p:Consfiguration=Debug
xcopy /y bin\Debug\*.* ..\Essentials\*.*
popd

@del Essentials.7z 1>nul 2>nul
x86\7z a -t7z -mx=9 -sfx7zCon.sfx -mfb=128 -md=128m -ms=on -mqs -xr!Essentials.7z.exe Essentials.7z.exe
del Parallel-Download.*