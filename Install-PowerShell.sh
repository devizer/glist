#!/usr/bin/env bash
# INSTALL_DIR=/opt/powershell; VER="--stable|--prerelase"; url=https://raw.githubusercontent.com/devizer/glist/master/Install-PowerShell.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash -s $VER
INSTALL_DIR=${INSTALL_DIR:-/opt/powershell}
sudo mkdir -p "${INSTALL_DIR}"
pushd "${INSTALL_DIR}"
sudo rm -rf *
url=https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64-fxdependent.tar.gz
if [[ "$1" == "--pre"* ]]; then
  url=https://github.com/PowerShell/PowerShell/releases/download/v7.0.0-preview.6/powershell-7.0.0-preview.6-linux-x64-fxdependent.tar.gz
fi
file=$(basename $url)
echo "Downloading $url"
sudo curl -kSL $url -o pwsh.tar.gz
tar xzf pwsh.tar.gz
rm -f pwsh.tar.gz
echo '#!/usr/bin/env bash
dotnet "'$INSTALL_DIR'/pwsh.dll" "$@"
' | sudo tee /usr/local/bin/pwsh > /dev/null
sudo chmod +x /usr/local/bin/pwsh

pwsh -c '$PSVersionTable'
