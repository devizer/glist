#!/bin/bash
f=/usr/lib/NUGET-Latest.exe
url=https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
cmd=/usr/bin/nuget
echo -e "\nInstalling nuget (Latest) as [$cmd]"
(command -v wget >> /dev/null) && sudo wget --no-check-certificate -O $f $url
if [ ! -f $f ]; then
  (command -v curl >> /dev/null) && sudo curl -o $f $url
fi

echo '#!/bin/sh
mono '$f' "$@"
' | sudo tee $cmd
chmod +x $cmd


f=/usr/lib/NUGET-3.4.4.exe
url=https://dist.nuget.org/win-x86-commandline/v3.4.4/nuget.exe
cmd=/usr/bin/nuget3
echo -e "\n ---------- Installing nuget (3.4.4) as [$cmd]"
(command -v wget >> /dev/null) && sudo wget --no-check-certificate -O $f $url
if [ ! -f $f ]; then
  (command -v curl >> /dev/null) && sudo curl -o $f $url
fi

echo '#!/bin/sh
mono '$f' "$@"
' | sudo tee $cmd
chmod +x $cmd

#  old:
#  #!/bin/sh
#  exec /usr/bin/cli /usr/lib/nuget/NuGet.exe "$@"

# One Line Installer: 
# wget -q -nv --no-check-certificate -O - https://raw.githubusercontent.com/devizer/glist/master/bin/install-nuget-latest.sh | bash
