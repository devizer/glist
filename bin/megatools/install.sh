#!/usr/bin/env bash
if [[ $(uname -m) == armv7* ]]; then arch=arm32; else arch=arm64; fi; echo "ARM Architecture: $arch"
url=https://raw.githubusercontent.com/devizer/glist/master/bin/megatools/megatools-$arch.tar.gz
$work=$(mktemp -d mega-XXXXXXXX)
pushd $work
wget --nocheck-certificate -O _mega.tar.gz $url
tar xzf _mega.tar.gz
cd megatools*
./megatools --version
popd

