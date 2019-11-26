set -e
set -u



function header() {
  if [[ $(uname -s) != Darwin ]]; then
    startAt=${startAt:-$(date +%s)}; elapsed=$(date +%s); elapsed=$((elapsed-startAt)); elapsed=$(TZ=UTC date -d "@${elapsed}" "+%_H:%M:%S");
  fi
  LightGreen='\033[1;32m'; Yellow='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'; LightGray='\033[1;2m';
  printf "${LightGray}${elapsed:-}${NC} ${LightGreen}$1${NC} ${Yellow}$2${NC}\n"; 
}
counter=0;
function Say() { echo ""; counter=$((counter+1)); header "STEP $counter" "$1"; }

Say "export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0"
export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0

Say "1st Install"
apt update; apt-get install curl htop mc lsof git nano -y
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1; 
export DOTNET_CLI_TELEMETRY_OPTOUT=1;

Say "Install dotnet dependencies"
url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash


function alt_pwsh() {
    Say "Install POWERSHELL-PREVIEW Alternative"
    url=https://github.com/PowerShell/PowerShell/releases/download/v7.0.0-preview.5/powershell-7.0.0-preview.5-linux-x64.tar.gz
    curl -o powershell-7.0.0-preview.5-linux-x64.tar.gz -L $url
    mkdir -p /opt/pwsh
    tar xzf powershell-7.0.0-preview.5-linux-x64.tar.gz -C /opt/pwsh
    export PATH="/opt/pwsh:$PATH"
    pwsh -c '$PSVersionTable'
}

if [[ "$(uname -m)" == "x86_64"* ]]; then
    Say "Install POWERSHELL-PREVIEW"
    bash <(curl -s https://raw.githubusercontent.com/PowerShell/PowerShell/master/tools/install-powershell.sh) --preview || alt_pwsh 
    pwsh -c '$PSVersionTable'
else
    Say "Skipping POWERSHELL-PREVIEW"
fi


Say "Install dotnet $DOTNET_VER"
curl -ksSL -o dotnet-install.sh https://dot.net/v1/dotnet-install.sh
source dotnet-install.sh -c $DOTNET_VER -i /usr/share/dotnet

# ARM?
# curl -ksSL -o dotnet-sdk-3.0.100-linux-arm.tar.gz https://download.visualstudio.microsoft.com/download/pr/8ddb8193-f88c-4c4b-82a3-39fcced27e91/b8e0b9bf4cf77dff09ff86cc1a73960b/dotnet-sdk-3.0.100-linux-arm.tar.gz
# tar xzf dotnet-sdk-3.0.100-linux-arm.tar.gz


export PATH="$PATH:/root/.dotnet/tools"
export DOTNET_ROOT=/usr/share/dotnet
if false; then 
    Say "Install ugly PowerShell"
    dotnet tool install PowerShell -g
    pwsh 'Write-Host "Im powershell"'
fi

mkdir /app
pushd /app
Say "dotnet new console @[$(pwd)]"
time dotnet new console --no-restore
Say "dotnet restore @[$(pwd)]"
time dotnet restore
Say "dotnet run @[$(pwd)]"
time dotnet run
rid=$(dotnet --info | grep RID | awk '{print $2}')
Say "Publish console as RID=$rid @[$(pwd)]"
dotnet publish -c Release -o ./bin -r $rid --self-contained
Say "Run bin/app @[$(pwd)]"
bin/app
popd


Say "Install Node"
script=https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# nvm install --lts node  # 10.16.3
nvm install node          # 12.12
npm install yarn npm npx npm-check-updates --global

Say "Build Universe.W3Top/ClientApp"
git clone https://github.com/devizer/KernelManagementLab
pushd KernelManagementLab/Universe.W3Top/ClientApp
yarn install
yarn build
popd


Say "NPX my-react1"
npx create-react-app my-react-app1
pushd my-react-app1
Say "NPX my-react1: yarn install with retry"
yarn install || yarn install || yarn install || true
Say "NPX my-react1: yarn build"
yarn build
# Say "NPX my-react1: yarn test"
# yarn test | cat
popd

Say "Done"

# dotnetsay 

