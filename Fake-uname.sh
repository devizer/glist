#!/usr/bin/env bash

# Tool to fake the output in chroot to adjust the
# used kernel version in different Makefiles.

# prepare system by rehash uname from /bin/uname
# to /tmp/uname: "hash -p /tmp/uname uname"

function _generate_() {
for a in a s n r v m p i o; do eval "uname -$a"; done
for a in a s n r v m p i o; do v=$(eval "uname -$a"); echo $a') echo "'$v'" ;;'; done
}

function _install_() {
if [[ ! -f /usr/bin/uname-bak ]]; then
  sudo cp /usr/bin/uname /usr/bin/uname-bak 
fi
script=https://raw.githubusercontent.com/devizer/glist/master/Fake-uname.sh; 
cmd="(wget --no-check-certificate -O /tmp/Fake-uname.sh $script 2>/dev/null || curl -kSL -o /tmp/Fake-uname.sh $script)"
eval "$cmd || $cmd || $cmd" && sudo cp /tmp/Fake-uname.sh /usr/bin/uname && sudo chmod +x /usr/bin/uname; echo "OK"
}

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

if [ $# -eq 0 ]; then
	/bin/uname
fi

while getopts "asnrvmpio" opt; do
 case "$opt" in
  a) echo "Linux $(hostname) 4.19.0-18-armmp-lpae #1 SMP Debian 4.19.208-1 (2021-09-29) armv7l GNU/Linux" ;;
  s) echo "Linux" ;;
  n) echo "$(hostname)" ;;
  r) echo "4.19.0-18-armmp-lpae" ;;
  v) echo "#1 SMP Debian 4.19.208-1 (2021-09-29)" ;;
  m) echo "armv7l" ;;
  p) echo "unknown" ;;
  i) echo "unknown" ;;
  o) echo "GNU/Linux" ;;
 esac
done