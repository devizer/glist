#!/usr/bin/env bash

# wget --no-check-certificate -O kubuntu-18.10-desktop-amd64.iso http://cdimage.ubuntu.com/kubuntu/releases/18.10/release/kubuntu-18.10-desktop-amd64.iso
if [ ! -f kubuntu-18.10-desktop-amd64.iso.ok ]; then
  curl -kL -o kubuntu-18.10-desktop-amd64.iso http://cdimage.ubuntu.com/kubuntu/releases/18.10/release/kubuntu-18.10-desktop-amd64.iso \
  && echo ok > kubuntu-18.10-desktop-amd64.iso.ok
fi
mkdir -p /mnt/dvd "/live linux"
mount -o loop kubuntu-18.10-desktop-amd64.iso /mnt/dvd
mount -o loop /mnt/dvd/casper/filesystem.squashfs "/live linux"



