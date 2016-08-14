#!/bin/bash -e
set -e
sudo apt-get remove --purge automake libtool -y
mkdir -p ~/src/auto
cd ~/src/auto

wget --no-check-certificate -O automake-1.15.tar.gz https://ftp.gnu.org/gnu/automake/automake-1.15.tar.gz
wget --no-check-certificate -O libtool-2.4.6.tar.gz https://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.gz


for a in libtool-2.4.6 automake-1.15; do
  pv $a.tar.gz | tar xzf -
  cd $a
  export CFLAGS="-O0"
  export CXXFLAGS="$CFLAGS"
  export CPPFLAGS="$CFLAGS"
  time ./configure
  make
  sudo make install
  cd ..
done

