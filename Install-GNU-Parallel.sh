#!/usr/bin/env bash
set -eu; set -o pipefail
# Here is one line installer 
# export PREFIX="${PREFIX:-/usr/local}"
# Run-Remote-Script https://raw.githubusercontent.com/devizer/glist/master/Install-GNU-Parallel.sh;

perf_version_long="$(perl --version | grep -v -e '^$' | head -1)"
url='https://ftp.gnu.org/gnu/parallel/parallel-20220822.tar.bz2'
Say "Installing parallel $(basename "$url"); Perl Version: [$perf_version_long]"
echo "Minimum perl version 5.8 is required"
dir="$(basename "$file")"
mkdir -p $HOME/build/parallel/source
file="$HOME/build/parallel/parallel-20220822.tar.bz2"
try-and-retry curl -kSL -o "$file" "$url"
cd $HOME/build/parallel/source
tar xjf "$file"
rm -f "$file" || true
cd *
time (./configure --prefix="${INSTALL_PREFIX:-/usr/local}" && make -j && sudo make install)
rm -rf $HOME/build/parallel || true

mkdir -p ~/.parallel && touch ~/.parallel/will-cite
if [[ -n "$(Get-Sudo-Command)" ]]; then
  # "$(Get-Sudo-Command)" mkdir -p /root 2>/dev/null
  if [[ -d /root ]]; then
    "$(Get-Sudo-Command)" mkdir -p /root/.parallel && "$(Get-Sudo-Command)" touch /root/.parallel/will-cite
  fi
fi

Test-Parallel() {
  find /tmp | parallel -j 3 sh -c 'x=5; echo -n "T{%}: "; echo -n {}; echo -n " is "; echo {}' \;
  time (find /tmp | parallel -j 3 sh -c 'x=5; echo -n "T{%}: "; Colorize -NoNewLine Cyan {}; echo -n " "; if [[ -f "{}" ]]; then Colorize Green $(Get-File-Size "{}"); elif [[ -d "{}" ]]; then Colorize Green $(Get-Folder-Size "{}"); else echo; fi' \; )
}
