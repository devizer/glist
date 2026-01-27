set -eu; set -o pipefail
work=$HOME/build/bzip-src
mkdir -p "$work"
pushd "$work"
# git clone git://sourceware.org/git/bzip2.git
url=https://github.com/libarchive/bzip2/archive/refs/tags/bzip2-1.0.8.tar.gz
echo "Installing BZIP2 [https://github.com/libarchive/bzip2/archive/refs/tags/bzip2-1.0.8.tar.gz] to [/usr/local]"
try-and-retry curl -kfSL -o _bzip2-1.0.8.tar.gz https://github.com/libarchive/bzip2/archive/refs/tags/bzip2-1.0.8.tar.gz
tar xzf _bzip2-1.0.8.tar.gz
cd bzip2*
time sudo make -j install DESTDIR=/usr/local
popd
rm -rf "$work"
