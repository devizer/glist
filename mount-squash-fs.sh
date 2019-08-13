#!/usr/bin/env bash

# wget --no-check-certificate -O kubuntu-18.10-desktop-amd64.iso http://cdimage.ubuntu.com/kubuntu/releases/18.10/release/kubuntu-18.10-desktop-amd64.iso
url=http://cdimage.ubuntu.com/kubuntu/releases/18.04/release/kubuntu-18.04.3-desktop-amd64.iso
file=$(basename $url)
if [ ! -f ${file}.ok ]; then
  curl -kL -o ${file} ${url} \
  && echo ok > ${file}.ok
fi
mkdir -p /mnt/dvd "/live linux"
mount -o loop ${file} /mnt/dvd
mount -o loop /mnt/dvd/casper/filesystem.squashfs "/live linux"




