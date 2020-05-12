#!/usr/bin/env bash
# export PS_INSTALL_DIR=/opt/powershell PS_VER="stable|prerelase"; url=https://raw.githubusercontent.com/devizer/glist/master/Install-PowerShell.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

echo "
   Install:

   # Choose eiher prerease or stable version
   export PS_INSTALL_DIR=/opt/powershell PS_VER='stable|prerelase'; 
   url=https://raw.githubusercontent.com/devizer/glist/master/Install-PowerShell.sh; 
   (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

   Usage:

   pwsh -c '$y=13/0' || echo ERROR
   pwsh -c '$y=42'   && echo NICE

" >/dev/null

ps_url_stable=https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64-fxdependent.tar.gz
ps_url_stable=https://github.com/PowerShell/PowerShell/releases/download/v6.2.4/powershell-6.2.4-linux-x64-fxdependent.tar.gz
ps_url_prerelase=https://github.com/PowerShell/PowerShell/releases/download/v7.0.0-preview.6/powershell-7.0.0-preview.6-linux-x64-fxdependent.tar.gz
ps_url_prerelase=https://github.com/PowerShell/PowerShell/releases/download/v7.1.0-preview.2/powershell-7.1.0-preview.2-linux-x64-fxdependent.tar.gz

PS_INSTALL_DIR=${PS_INSTALL_DIR:-/opt/powershell}
url=$ps_url_stable
if [[ "$1" == "--pre"* || "${PS_VER:-}" == "pre"* ]]; then
  url=$ps_url_prerelase
fi

function install_powershell() {
    sudo mkdir -p "${PS_INSTALL_DIR}"
    pushd "${PS_INSTALL_DIR}"
    sudo rm -rf *
    file=$(basename $url)
    echo "Downloading $url"
    cmd="sudo wget -q -nv --no-check-certificate -O pwsh.tar.gz $url 2>/dev/null || sudo curl -kSL -o pwsh.tar.gz $url"
    # retry pattern
    eval "$cmd" || eval "$cmd" || eval "$cmd"
    sudo tar xzf pwsh.tar.gz
    sudo rm -f pwsh.tar.gz
    echo '#!/usr/bin/env bash
    if [[ -f "'$PS_INSTALL_DIR'/pwsh.dll" ]]; then
        dotnet "'$PS_INSTALL_DIR'/pwsh.dll" "$@"
        exit $?
    else
        echo "Missing framework depended Powershell: '$PS_INSTALL_DIR'/pwsh.dll" >&2
        exit 1
    fi
    ' | sudo tee /usr/local/bin/pwsh > /dev/null
    sudo chmod +x /usr/local/bin/pwsh

    echo -e "PowerShell version is:\n$(pwsh -c '$PSVersionTable')"
    popd
}

install_powershell
