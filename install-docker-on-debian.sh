#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/install-docker-on-debian.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash

function header42() { LightGreen='\033[1;32m';Yellow='\033[1;33m';RED='\033[0;31m'; NC='\033[0m'; printf "${LightGreen}$1${NC} ${Yellow}$2${NC}\n"; }

if true || [ "$(command -v docker)" == "" ]; then 
  header42 "Installing docker from" "download.docker.com repo"
  source /etc/os-release
  sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get clean

  sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y && sudo apt-get clean
  curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo apt-key add -

  sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 7EA0A9C3F273FCD8
  sudo add-apt-repository \
     "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/$ID \
     $(lsb_release -cs) \
     stable"
  sudo apt-get update
  apt-cache policy docker-ce
  sudo apt-get install -y docker-ce && sudo apt-get clean && sudo systemctl status docker | head -n 88
fi

if [ "$(command -v docker-compose)" == "" ]; then 
  header42 "Installing" "docker-compose"
  sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

