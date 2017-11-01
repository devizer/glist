del Essentials.7z 1>nul 2>nul
C:\Apps\7-Zip-x86\7z a -t7z -mx=9 -mfb=128 -md=128m -ms=on -xr!Essentials.7z.exe Essentials.7z
copy /b C:\Apps\7-Zip-x86\7zCon.sfx + Essentials.7z Essentials.7z.exe
del Essentials.7z