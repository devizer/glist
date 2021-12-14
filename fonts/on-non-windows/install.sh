#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/fonts/on-non-windows/install.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash

pushd /tmp
for f in Barlow_Semi_Condensed Roboto Fira OpenSans liberation ubuntu-font-family Google-SuperFamilies; do
  echo $f
  wget --no-check-certificate -O $f.zip https://raw.githubusercontent.com/devizer/glist/master/fonts/$f.zip
  unzip -o $f.zip -d fontfiles/
  rm -f $f.zip
done

pushd fontfiles
if [ -d "/usr/share/fonts" ]; then target=/usr/share/fonts; else target=/usr/local/share/fonts; fi
for i in $(ls -d */); do 
  dir=${i%%/}
  echo Dir: $dir
  sudo mkdir -p $target/truetype
  sudo cp -rf "./$dir" $target/truetype/
  rm -rf $dir
done
popd
popd

fc-cache -f -v

