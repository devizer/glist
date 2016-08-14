#~/bin/bash
sudo apt-get install libglib2.0-0 libglib2.0-data -y

mkdir -p ~/src && cd ~/src
wget --no-check-certificate -O libgdiplus-3.12.tar.gz https://github.com/mono/libgdiplus/archive/3.12.tar.gz
pv libgdiplus-3.12.tar.gz | tar xzf -
cd libgdiplus-3.12
time (./autogen.sh --with-pango --prefix=/opt/libgdiplus-3.12 | tee autogen.log)
time (make | tee make.log)
(sudo make install) | install.log
