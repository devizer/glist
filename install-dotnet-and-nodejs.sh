#!/usr/bin/env bash
# Here is one line installer 
# script=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-and-nodejs.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash -s dotnet node pwsh

set -e
set -u
echo '.NET SDK 2.*/3.0, NodeJS LTS 10.5.3 and powershell 6.2 generic binaries installer. 
Supported architectures: Linux x64, armv7 (32-bit), aarch64 (64-bit) and MacOS 10.12+
System requirements: GLIBC_2.17+, GLIBCXX_3.4.20+'

TMPDIR="${TMPDIR:-/tmp}"
echo Download buffer location: $TMPDIR

# ARM 64
# https://download.visualstudio.microsoft.com/download/pr/39601b46-a250-46c3-92f0-68493e07fe5c/3bc40cf7868dcdd05ce353e253fd266c/dotnet-sdk-3.0.100-preview4-011223-linux-arm64.tar.gz
export links_arm64='
https://download.visualstudio.microsoft.com/download/pr/0af74ee1-47bb-43bd-b55f-1657f079c309/6649fd1bc91b14aee4a6b4ed44a2f45d/dotnet-sdk-2.2.301-linux-arm64.tar.gz
https://download.visualstudio.microsoft.com/download/pr/cbc83a0e-895c-4959-99d9-21cd11596e64/b0e59c2ba2bd3ef0f592acbeae7ab27d/dotnet-sdk-3.0.100-linux-arm64.tar.gz
'
export link_node_arm64='https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-arm64.tar.xz'
export link_node_arm64='https://nodejs.org/dist/v12.2.0/node-v12.2.0-linux-arm64.tar.xz'
export link_node_arm64='https://nodejs.org/dist/v10.16.0/node-v10.16.0-linux-arm64.tar.xz'
export link_node_arm64='https://nodejs.org/dist/v12.12.0/node-v12.12.0-linux-arm64.tar.xz'
export link_pwsh_arm64='https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/powershell-6.2.0-linux-arm64.tar.gz'
export link_pwsh_arm64='https://github.com/PowerShell/PowerShell/releases/download/v6.2.2/powershell-6.2.2-linux-arm64.tar.gz'
export link_pwsh_arm64='https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-arm64.tar.gz'


# X64
# https://download.visualstudio.microsoft.com/download/pr/ece856bb-de15-4df3-9677-67cc817ffc1b/521da52132d23deae5400b8e19e23691/dotnet-sdk-2.2.204-linux-x64.tar.gz
export links_x64='
https://download.visualstudio.microsoft.com/download/pr/46411df1-f625-45c8-b5e7-08ab736d3daa/0fbc446088b471b0a483f42eb3cbf7a2/dotnet-sdk-2.2.402-linux-x64.tar.gz
https://download.visualstudio.microsoft.com/download/pr/886b4a4c-30af-454b-8bec-81c72b7b4e1f/d1a0c8de9abb36d8535363ede4a15de6/dotnet-sdk-3.0.100-linux-x64.tar.gz
'

export link_node_x64='https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.xz'
export link_node_x64='https://nodejs.org/dist/v12.12.0/node-v12.12.0-linux-x64.tar.xz'
export link_pwsh_x64='https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/powershell-6.2.0-linux-x64.tar.gz'
export link_pwsh_x64='https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-x64.tar.gz'

# ARM
export links_arm32='
https://download.visualstudio.microsoft.com/download/pr/74ce4696-c78e-45c0-9cb2-f504e8d00a6f/152f760e7f1d9f3448038e3864ee5277/dotnet-sdk-2.2.105-linux-arm.tar.gz
'
export links_arm32='
https://download.visualstudio.microsoft.com/download/pr/fc0c7de2-24cb-45e4-a354-df612b5c3420/b8cc998c1c66717309d1e59ea979e1f3/dotnet-sdk-2.2.204-linux-arm.tar.gz
https://download.visualstudio.microsoft.com/download/pr/8ddb8193-f88c-4c4b-82a3-39fcced27e91/b8e0b9bf4cf77dff09ff86cc1a73960b/dotnet-sdk-3.0.100-linux-arm.tar.gz
'
export link_node_arm32='https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-armv7l.tar.xz'
export link_node_arm32='https://nodejs.org/dist/v12.12.0/node-v12.12.0-linux-armv7l.tar.xz'

export link_pwsh_arm32='https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/powershell-6.2.0-linux-arm32.tar.gz'
export link_pwsh_arm32='https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-linux-arm32.tar.gz'


# OSX
export links_osx='
https://download.visualstudio.microsoft.com/download/pr/405eba1f-9a78-4ac0-99f3-3fad5107022c/d793c7a75613fb985bb6f7aff522437e/dotnet-sdk-2.2.204-osx-x64.tar.gz
https://download.visualstudio.microsoft.com/download/pr/b9251194-4118-41cb-ae05-6763fb002e5d/1d398b4e97069fa4968628080b617587/dotnet-sdk-3.0.100-osx-x64.tar.gz
'
export link_node_osx='https://nodejs.org/dist/v10.15.3/node-v10.15.3-darwin-x64.tar.gz'
export link_node_osx='https://nodejs.org/dist/v12.12.0/node-v12.12.0-darwin-x64.tar.gz'
export link_pwsh_osx='https://github.com/PowerShell/PowerShell/releases/download/v6.2.0/powershell-6.2.0-osx-x64.tar.gz'
export link_pwsh_osx='https://github.com/PowerShell/PowerShell/releases/download/v6.2.3/powershell-6.2.3-osx-x64.tar.gz'

# RHEL6
export links_rhel6='
https://download.visualstudio.microsoft.com/download/pr/e2943c98-ddba-4768-af91-9936995d5b5d/b10543dc39973d697201a7a13419a9e6/dotnet-sdk-2.2.204-rhel.6-x64.tar.gz
https://download.visualstudio.microsoft.com/download/pr/5d6a0da0-2da2-4c2c-ba9c-f086566d527f/7e2b7492d4142ae6e7d7c6a561f71cc0/dotnet-sdk-3.0.100-rhel.6-x64.tar.gz'
export link_node_rhel6=$link_node_x64
export link_pwsh_rhel6=$link_pwsh_x64


function header() { LightGreen='\033[1;32m';Yellow='\033[1;33m';RED='\033[0;31m'; NC='\033[0m'; printf "${LightGreen}$1${NC} ${Yellow}$2${NC}\n"; }

m=$(uname -m)
if [[ $m == armv7* ]]; then arch=arm32; elif [[ $m == aarch64* ]] || [[ $m == armv8* ]]; then arch=arm64; elif [[ $m == x86_64 ]]; then arch=x64; fi; if [[ $(uname -s) == Darwin ]]; then arch=osx; fi;
if [ ! -e /etc/os-release ] && [ -e /etc/redhat-release ]; then
  redhatRelease=$(</etc/redhat-release)
  if [[ $redhatRelease == "CentOS release 6."* || $redhatRelease == "Red Hat Enterprise Linux Server release 6."* ]]; then
    arch=rhel6;
  fi
fi


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
  sudo mkdir -p $TMPDIR/dotnet-tmp
  
  # DOWNLOADING
  counter=$((counter+1))
  header "[Step $counter] Downloading" $filename
  if [[ "$(command -v curl)" == "" ]]; then
    sudo wget --no-check-certificate -O $TMPDIR/dotnet-tmp/$filename $url
  else
    sudo curl -L -o $TMPDIR/dotnet-tmp/$filename $url
  fi
  sudo mkdir -p $todir
  pushd $todir >/dev/null
  
  # EXTRACTING
  counter=$((counter+1))
  header "[Step $counter] Extracting" $filename
  if [[ $filename =~ .tar.gz$ ]]; then tarcmd=xzf; else tarcmd=xJf; fi
  if [[ ! -z "$(command -v pv)" ]]; then
    pv $TMPDIR/dotnet-tmp/$filename | sudo tar $tarcmd -
  else
    sudo tar $tarcmd $TMPDIR/dotnet-tmp/$filename
  fi
  popd >/dev/null
  sudo rm -f $TMPDIR/dotnet-tmp/$filename
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
script=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-and-nodejs.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash -s dotnet node pwsh
'
fi

if [[ ! -z "$_node" ]]; then install_node; fi
if [[ ! -z "$_dotnet" ]]; then install_dotnet; fi
if [[ ! -z "$_pwsh" ]]; then install_pwsh; fi

sudo rm -rf $TMPDIR/dotnet-tmp >/dev/null 2>&1 || true

export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
[[ ! -z "$(command -v node)" ]]   && header "Installed node:" "$(node --version)"                            || echo node is not found
[[ ! -z "$(command -v npm)" ]]    && header "Installed npm:" "$(npm --version)"                              || echo npm is not found
[[ ! -z "$(command -v yarn)" ]]   && header "Installed yarn:" "$(yarn --version)"                            || echo yarn is not found
[[ ! -z "$(command -v dotnet)" ]] && (header "Installed dotnet:" "$(dotnet --version):"; dotnet --list-sdks) || echo dotnet is not found
psCode='"$($PSVersionTable.PSVersion) using $([System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription)"'
[[ ! -z "$(command -v pwsh)" ]]   && header "Installed pwsh:" "$(pwsh -c $psCode)"                           || echo pwsh is not found
