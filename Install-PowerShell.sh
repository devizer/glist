#!/usr/bin/env bash
# export PS_INSTALL_DIR=/opt/powershell PS_VER="stable|prerelase"; url=https://raw.githubusercontent.com/devizer/glist/master/Install-PowerShell.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
PS_INSTALL_DIR=${PS_INSTALL_DIR:-/opt/powershell}
url=https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64-fxdependent.tar.gz
if [[ "$1" == "--pre"* || "${PS_VER:-}" == "pre"* ]]; then
  url=https://github.com/PowerShell/PowerShell/releases/download/v7.0.0-preview.6/powershell-7.0.0-preview.6-linux-x64-fxdependent.tar.gz
fi

function install_powershell() {
    sudo mkdir -p "${PS_INSTALL_DIR}"
    pushd "${PS_INSTALL_DIR}"
    sudo rm -rf *
    file=$(basename $url)
    echo "Downloading $url"
    sudo curl -kSL $url -o pwsh.tar.gz
    tar xzf pwsh.tar.gz
    rm -f pwsh.tar.gz
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
}

install_powershell
