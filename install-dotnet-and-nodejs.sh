#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-and-nodejs.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash -s dotnet node pwsh
# wget -q -nv --no-check-certificate -O - https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-and-nodejs.sh | bash -s dotnet node pwsh

set -e
set -u
echo '.NET SDK 2.*/3.0, node 10.5.3 and powershell 6.1/6.2 generic binaries installer. 
Supported architectures: Linux x64, armv7 (32-bit), aarch64 (64-bit) and MacOS 10.12+
System requirements: GLIBC_2.17+, GLIBCXX_3.4.20+'

# ARM 64
export links_arm64='
https://download.visualstudio.microsoft.com/download/pr/50979c85-1634-4c40-a4d0-4d25c9dae08d/cfa1d7e5ef765cef1d2c9127c9e14599/dotnet-sdk-2.2.203-linux-arm64.tar.gz
https://download.visualstudio.microsoft.com/download/pr/39601b46-a250-46c3-92f0-68493e07fe5c/3bc40cf7868dcdd05ce353e253fd266c/dotnet-sdk-3.0.100-preview4-011223-linux-arm64.tar.gz
'
export link_node_arm64='https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-arm64.tar.xz'
export link_node_arm64='https://nodejs.org/dist/v12.2.0/node-v12.2.0-linux-arm64.tar.xz'
export link_pwsh_arm64='https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/powershell-6.2.0-linux-arm64.tar.gz'
export link_pwsh_arm64='https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/powershell-6.2.0-linux-arm64.tar.gz'

# X64
export links_x64='
https://download.visualstudio.microsoft.com/download/pr/647f8505-3bf0-48c5-ac0f-3839be6816d7/d0c2762ded5a1ded3c79b1e495e43b7c/dotnet-sdk-2.2.203-linux-x64.tar.gz
'

export link_node_x64='https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.xz'
export link_pwsh_x64='https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/powershell-6.2.0-linux-x64.tar.gz'

# ARM
export links_arm32='
https://download.visualstudio.microsoft.com/download/pr/74ce4696-c78e-45c0-9cb2-f504e8d00a6f/152f760e7f1d9f3448038e3864ee5277/dotnet-sdk-2.2.105-linux-arm.tar.gz
'
export links_arm32='
https://download.visualstudio.microsoft.com/download/pr/e5573b57-df74-4b5b-8cd8-06973b66c3ac/b9ee29318ad2d87fa05adfaf74a8271c/dotnet-sdk-2.2.203-linux-arm.tar.gz
'
export link_node_arm32='https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-armv7l.tar.xz'
export link_pwsh_arm32='https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/powershell-6.2.0-linux-arm32.tar.gz'


# OSX
export links_osx='
https://download.visualstudio.microsoft.com/download/pr/d4f74ee8-c6f1-4288-bcf2-4a8515601020/10533119f42116bb4ce53eef285fc4a6/dotnet-sdk-2.2.106-osx-x64.tar.gz

'

export link_node_osx='https://nodejs.org/dist/v10.15.3/node-v10.15.3-darwin-x64.tar.gz'
export link_pwsh_osx='https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/powershell-6.2.0-osx-x64.tar.gz'

function header() { LightGreen='\033[1;32m';Yellow='\033[1;33m';RED='\033[0;31m'; NC='\033[0m'; printf "${LightGreen}$1${NC} ${Yellow}$2${NC}\n"; }

if [[ $(uname -m) == armv7* ]]; then arch=arm32; else arch=arm64; fi; if [[ $(uname -m) == x86_64 ]]; then arch=x64; fi; if [[ $(uname -s) == Darwin ]]; then arch=osx; fi;
header "The current OS architecture" $arch
# if [ -f check-links.sh ]; then (. check-links.sh); fi; exit

eval links='$'links_$arch
eval link_node='$'link_node_$arch
eval link_pwsh='$'link_pwsh_$arch

function extract () {
  url=$1
  todir=$2
  symlinks_pattern=$3
  filename=$(basename $1)
  sudo mkdir -p /tmp/dotnet-tmp
  
  # DOWNLOADING
  counter=$((counter+1))
  header "[Step $counter] Downloading" $filename
  if [[ "$(command -v curl)" == "" ]]; then
    sudo wget --no-check-certificate -O /tmp/dotnet-tmp/$filename $url
  else
    sudo curl -L -o /tmp/dotnet-tmp/$filename $url
  fi
  sudo mkdir -p $todir
  pushd $todir >/dev/null
  
  # EXTRACTING
  counter=$((counter+1))
  header "[Step $counter] Extracting" $filename
  if [[ $filename =~ .tar.gz$ ]]; then tarcmd=xzf; else tarcmd=xJf; fi
  if [[ ! -z "$(command -v pv)" ]]; then
    pv /tmp/dotnet-tmp/$filename | sudo tar $tarcmd -
  else
    sudo tar $tarcmd /tmp/dotnet-tmp/$filename
  fi
  popd >/dev/null
  sudo rm -f /tmp/dotnet-tmp/$filename
  add_symlinks $symlinks_pattern $todir
}

function add_symlinks() { 
  pattern=$1
  dir=$2
  if [[ $arch == osx ]]; then sudo mkdir -p /usr/local/bin; fi
  if [ -d "/usr/local/bin" ]; then target="/usr/local/bin"; else target="/usr/bin"; fi;
  pushd "$dir" >/dev/null
  files=$(eval echo $pattern)
  for f in $files; do
    # echo Creating a link in $target/ to: $PWD/$f
    if [[ -x $f ]]; then sudo ln -s -f "$PWD/$f" "$target/$(basename $f)"; header "Created a link in $target/ to:" "$PWD/$f"; fi
  done
  popd >/dev/null
}

counter=0;total=4; for dotnet_url in $links; do total=$((total+2)); done

# node, npm and yarn
function install_node() {
  sudo rm -rf /opt/node >/dev/null 2>&1
  extract $link_node "/opt/node" 'skip-symlinks'

  # adding support for global packages
  npm=$(ls -1 /opt/node/node*/bin/npm)
  nodePath=$(dirname $(ls /opt/node/node*/bin/node))
  export PATH="$nodePath:$PATH"
  printf "\n\n"'export PATH="'$nodePath':$PATH"'"\n\n" | tee -a ~/.bashrc >/dev/null

  header "Upgrading and installing" 'npm & yarn (latest)'
  sudo bash -c "PATH=\"$nodePath:$PATH\"; npm install yarn npm npm-check-updates --global"
  sudo rm -rf ~/.npm
  add_symlinks 'node*/bin/*' /opt/node
}

# dotnet support upgrade by overwriting prev versions
function install_dotnet() {
  for dotnet_url in $links; do
    extract $dotnet_url "/opt/dotnet" 'dotnet'
  done
}

# powershell with a execution (+x) fix
function install_pwsh() {
  sudo rm -rf /opt/powershell >/dev/null 2>&1
  extract $link_pwsh "/opt/powershell" 'skip-pwsh-symlinks'
  # There is a bug with official powershell distribution. It is a fix:
  sudo chmod 775 /opt/powershell/pwsh
  add_symlinks pwsh /opt/powershell
}


_dotnet=
_node=
_pwsh=
_nothing=true
while [ $# -ne 0 ]; do
    param="$1"
    case "$param" in
        dotnet|node|pwsh)
            echo Enqueued installation of $param
            eval _$param=yes
            _nothing=
            ;;
        *)
            echo "Unknown argument \`$param\`"
            ;;
    esac
    shift
done

if [[ ! -z "$_nothing" ]]; then 
  echo '
usage:
wget -q -nv --no-check-certificate -O - https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-and-nodejs.sh | bash -s dotnet node pwsh
'
fi

if [[ ! -z "$_node" ]]; then install_node; fi
if [[ ! -z "$_dotnet" ]]; then install_dotnet; fi
if [[ ! -z "$_pwsh" ]]; then install_pwsh; fi

sudo rm -rf /tmp/dotnet-tmp >/dev/null 2>&1 || true
[[ ! -z "$(command -v node)" ]]   && header "Installed node:" "$(node --version)"                            || echo node is not found
[[ ! -z "$(command -v npm)" ]]    && header "Installed npm:" "$(npm --version)"                              || echo npm is not found
[[ ! -z "$(command -v yarn)" ]]   && header "Installed yarn:" "$(yarn --version)"                            || echo yarn is not found
[[ ! -z "$(command -v dotnet)" ]] && (header "Installed dotnet:" "$(dotnet --version):"; dotnet --list-sdks) || echo dotnet is not found
psCode='"$($PSVersionTable.PSVersion) using $([System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription)"'
[[ ! -z "$(command -v pwsh)" ]]   && header "Installed pwsh:" "$(pwsh -c $psCode)"                           || echo pwsh is not found
