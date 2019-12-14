set -e
set -u

script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-build-tools.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash

apt update
apt install sudo bash procps mc htop -y

apt-cache policy mono-complete



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

