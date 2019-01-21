#!/usr/bin/env bash
# Here is one line installer 
# wget -q -nv -O - https://raw.githubusercontent.com/devizer/glist/master/bin/megatools/install.sh | bash

if [ "$(command -v megatools)" == "" ]; then
  echo "Installing megatools for ARMv7 | AARCH64"
  if [[ $(uname -m) == armv7* ]]; then arch=arm32; else arch=arm64; fi; echo "ARM Architecture: $arch"
  url=https://raw.githubusercontent.com/devizer/glist/master/bin/megatools/megatools-$arch.tar.gz
  cd /tmp; work=$(mktemp -d mega-XXXXXXXX)
  pushd $work
  wget --no-check-certificate -O _mega.tar.gz $url
  tar xzf _mega.tar.gz
  cd megatools*
  sudo cp megatools /usr/local/bin/megatools
  popd
  rm -rf $work
fi
megatools --version | grep 'command line tools'
