#!/usr/bin/env bash
# Here is one line installer 
# export INSTALL_PREFIX=/usr/local
# Run-Remote-Script https://raw.githubusercontent.com/devizer/glist/master/Install-GNU-Parallel.sh;

perf_version_long="$(perl --version | grep -v -e '^$' | head -1)"
url='https://ftp.gnu.org/gnu/parallel/parallel-20220822.tar.bz2'
Say "Installing parallel $(basename "$url"); Perl Version: [$perf_version_long]"
file="${TMPDIR:-/tmp}/parallel-setup/parallel-20220822.tar.bz2"
dir="$(basename "$file")"
mkdir -p ~/build/parallel
cd ~/build/parallel
try-and-retry curl -kSL -o "$file" "$url"
tar xjf "$file"
rm -f "$file"
cd *
time (./configure --prefix="${INSTALL_PREFIX:-/usr/local}" && make -j && sudo make install)
rm -rm ~/build/parallel

# find /tmp | parallel -j 3 sh -c "x=5; echo -n "T{%}: "; echo -n {}; echo -n ' is '; echo {}" \;
