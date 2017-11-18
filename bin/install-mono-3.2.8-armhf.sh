#!/bin/bash
f=mono-3.2.8-armhf.tar.bz2
(command -v wget >> /dev/null) && wget --no-check-certificate -O $f https://raw.githubusercontent.com/devizer/glist/master/bin/$f
if [ ! -f $f ]; then
(command -v curl >> /dev/null) && curl -o $f https://raw.githubusercontent.com/devizer/glist/master/bin/$f
fi

echo -e "\n\nExtracting $f into /opt/mono/3.2.8 ...................."
if (command -v pv > /dev/null); then
  pv $f | tar xjf - -C /
else
  tar xjf $f -C /
fi
rm $f

echo -e "\n\n"
/opt/mono/3.2.8/bin/mono --version
echo '

-------------------------------------------------------------
Upgrade this env vars in order to use mono 3.2.8 as a default
mver=3.2.8
export PATH="/opt/mono/$mver/bin:$PATH"
export LD_LIBRARY_PATH="/opt/mono/$mver/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="/opt/mono/$mver/lib/pkgconfig:$PKG_CONFIG_PATH"
'

# One Line Installer: 
# wget -q -nv --no-check-certificate -O - https://raw.githubusercontent.com/devizer/glist/master/bin/install-mono-3.2.8-armhf.sh | bash
# curl https://raw.githubusercontent.com/devizer/glist/master/bin/install-mono-3.2.8-armhf.sh | bash

# https://raw.githubusercontent.com/devizer/glist/master/bin/install-mono-3.2.8-armhf.sh
