#!/usr/bin/env bash
# Origin: https://megatools.megous.com/builds/experimental/
# Here is one line installer 
# wget -q -nv --no-check-certificate -O - https://raw.githubusercontent.com/devizer/glist/master/bin/megatools/install.sh | bash
# Dependencies:
# sudo apt-get install musl gettext zlib1g openssl nghttp2 libcurl3 libffi6 libglib2.0-0

if [ "$(command -v megatools)" == "" ]; then
  echo "Installing megatools for ARMv7 | AARCH64 | X64 Linux"
  if [[ $(uname -m) == armv7* ]]; then arch=arm32; else arch=arm64; fi; if [[ $(uname -m) == x86_64 ]]; then arch=x64; fi; echo "Architecture: $arch"
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
