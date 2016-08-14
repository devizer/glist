#!/bin/bash
TO=$HOME/bin
mkdir -p $TO
old=`pwd`
wget --no-check-certificate -O /tmp/makeself-release.tar.gz https://github.com/megastep/makeself/tarball/master
t=`mktemp -d`
cd $t
tar xzf /tmp/makeself-release.tar.gz
cd *makeself*
ls -l
./makeself.sh --version
rm -rf $TO/makeself
mkdir -p $TO/makeself
cp * $TO/makeself
cp makeself* $TO
cd $old && rm -f /tmp/makeself-release.tar.gz && rm -rf $t
makeself.sh --version

echo '


export PATH="$PATH:$HOME/bin"
' >> ~/.bashrc

