#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/bin/install-nuget-6.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

f=/usr/local/share/nuget/nuget-latest.exe
url=https://dist.nuget.org/win-x86-commandline/v3.4.4/nuget.exe
url=https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
url=https://dist.nuget.org/win-x86-commandline/v5.11.6/nuget.exe
url=https://dist.nuget.org/win-x86-commandline/v5.6.0/nuget.exe
# msbuild 16.6 came with v5.6

sudo mkdir -p "$(dirname "$f")"
echo "Downloading '$url' as '$f'"
sudo curl -ksfSL -o "$f" "$url" || sudo curl -ksfSL -o "$f" "$url" || sudo curl -ksfSL -o "$f" "$url" || sudo rm -f "$f"

echo '#!/bin/sh
set -e
mono '$f' "$@"
' | sudo tee /usr/local/bin/nuget >/dev/null
sudo chmod +x /usr/local/bin/nuget 

if [[ -n "$(command -v mono)" ]]; then
  # Show nuget version
  nuget 2>&1 >/tmp/nuget.ver; cat /tmp/nuget.ver | head -1
fi
