#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/Install-Fake-UName.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

set -eu

machine="$(uname -m)"; 
bit="$(getconf LONG_BIT)"
[[ "$machine" == x86_64 ]]  && [[ "$bit" == "32" ]] && machine=i686
if [[ "$machine" == aarch64 ]] && [[ "$bit" == "32" ]]; then
  machine=armv7l
  [[ "$(dpkg --print-architecture)" == armel ]] && machine=armv5l
fi

# green yellow red
function say() { 
   local NC='\033[0m' Color_Green='\033[1;32m' Color_Red='\033[1;31m' Color_Yellow='\033[1;33m'; 
   local var="Color_${1:-}"
   local color="${!var}"
   shift 
   printf "${color:-}$*${NC}\n";
}

say Yellow "Installing FAKE UNAME for $(uname -m)]"
say Green "Adjected machine: [${machine}]"
echo ${machine} > /etc/system-uname-m
uname="$(command -v uname)"
sudo cp "${uname}" /usr/bin/uname-bak;
script=https://raw.githubusercontent.com/devizer/glist/master/Fake-uname.sh;
cmd="(wget --no-check-certificate -O /tmp/Fake-uname.sh $script 2>/dev/null || curl -kSL -o /tmp/Fake-uname.sh $script)"
eval "$cmd || $cmd || $cmd" && sudo cp /tmp/Fake-uname.sh /usr/bin/uname && sudo chmod +x /usr/bin/uname; echo "OK"
say Green "FAKE UNAME Result: [$(uname -m)]"
