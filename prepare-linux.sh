#!/usr/bin/env bash
# wget -q -nv --no-check-certificate -O - https://raw.githubusercontent.com/devizer/glist/master/prepare-linux.sh | bash
# url=https://raw.githubusercontent.com/devizer/glist/master/prepare-linux.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash

# 1a. Swap Used for PRTG
sudo mkdir -p /var/prtg/scripts

# V2
echo '#!/usr/bin/env bash
v=$(free -m | grep -E "[S|s]wap:" | awk '"'"'{print $3}'"'"')
t=$(free -m | grep -E "[S|s]wap:" | awk '"'"'{print $2}'"'"')
echo "0:$v:OK. Total swap is $t Mb"
' | sudo tee /var/prtg/scripts/SwapUsed.sh >/dev/null
sudo chmod 755 /var/prtg/scripts/SwapUsed.sh
echo "Swap Used: [$(/var/prtg/scripts/SwapUsed.sh)]"

# 1b. RAM Free for PRTG
sudo mkdir -p /var/prtg/scripts
echo '#!/usr/bin/env bash
v=$(free -m | sed -n 2,2p | awk '"'"'{print $4}'"'"')
t=$(free -m | sed -n 2,2p | awk '"'"'{print $2}'"'"')
echo "0:$v:OK. Total RAM is $t Mb"
' | sudo tee /var/prtg/scripts/RamFree.sh >/dev/null
sudo chmod 755 /var/prtg/scripts/RamFree.sh
echo "RAM Free: [$(/var/prtg/scripts/RamFree.sh)]"

# 2. drop-caches
echo '#!/bin/bash
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
' | sudo tee /usr/bin/drop-caches >/dev/null
sudo chmod 755 /usr/bin/drop-caches

# 3. color_prompt=yes
printf "\ncolor_prompt=yes\n" | sudo tee -a /etc/environment >/dev/null

# 4. list-packages
echo '#!/usr/bin/env bash
packages=$(dpkg --get-selections | grep -v deinstall | awk '"'"'{print $1}'"'"')
apt-cache --no-all-versions show $packages | 
    awk '"'"'$1 == "Package:" { p = $2 }
         $1 == "Size:"    { printf("%10d %s\n", $2, p) }'"'"' |
    sort -k1 -n
' | sudo tee /usr/bin/list-packages >/dev/null
sudo chmod +x /usr/bin/list-packages

echo '
export PS1="\[\033[01;31m\]\u@\h\[\033[00m\] \[\033[01;34m\]\w \$\[\033[00m\] "
' | tee -a ~/.bashrc >/dev/null


echo '#!/usr/bin/env bash
cd /
sudo rm -rf /var/lib/apt/lists/*
sudo rm -rf /var/cache/apt/*
sudo rm -rf /var/tmp/*
sudo rm -rf /tmp/*

cd /var/log
printf "\nDELETE LOGS in /var/log: "
for f in $(sudo find .); do
  if [[ -f "$f" ]]; then printf "$f "; sudo rm -f "$f"; fi
done
echo ""

sudo rm -rf $HOME/.cache/mozilla  2>/dev/null
sudo rm -rf $HOME/.Rider2018.3/system/resharper-host/local/Transient 2>/dev/null
sudo rm -rf $HOME/.cache/google-chrome 2>/dev/null
sudo rm -rf $HOME/.Rider2018.3/system/caches 2>/dev/null
sudo rm -rf $HOME/.Rider2018.3/system/log 2>/dev/null
df -hT | grep -E /$
' | sudo tee /usr/local/bin/del-cache
sudo chmod +x /usr/local/bin/del-cache
# /usr/local/bin/del-cache
