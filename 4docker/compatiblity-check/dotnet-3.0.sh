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

Say "1st Install"
apt update; apt-get install curl htop mc lsof git nano -y
# export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1; 
export DOTNET_CLI_TELEMETRY_OPTOUT=1;

Say "Install dotnet dependencies"
url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

Say "Install dotnet"
curl -L -o dotnet-install.sh https://dot.net/v1/dotnet-install.sh
source dotnet-install.sh -c 3.0 -i /usr/share/dotnet

Say "Compile console app1"
mkdir console1
pushd console1
time dotnet new console
time dotnet run
Say "Publish console app1"
dotnet publish -c Release -o ./bin -r linux-x64 --self-contained
Say "Run console app1"
bin/console1
popd

Say "Install PowerShell"
export PATH="$PATH:/root/.dotnet/tools"
export DOTNET_ROOT=/usr/share/dotnet
dotnet tool install PowerShell -g


Say "Install Node"
script=https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# nvm install --lts node  # 10.16.3
nvm install node          # 12.12
npm install yarn npm npx npm-check-updates --global

Say "NPX my-react1"
npx create-react-app my-react-app1
pushd my-react-app1
Say "NPX my-react1: yarn install with retry"
yarn install || yarn install || yarn install || true
Say "NPX my-react1: yarn build"
yarn build
Say "NPX my-react1: yarn test"
yarn test
popd

Say "Build Universe.W3Top/ClientApp"
git clone https://github.com/devizer/KernelManagementLab
pushd KernelManagementLab/Universe.W3Top/ClientApp
yarn install 
yarn build
popd

Say "Done"

# dotnetsay 

