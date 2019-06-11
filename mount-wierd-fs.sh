#!/usr/bin/env bash
# script=https://raw.githubusercontent.com/devizer/glist/master/mount-wierd-fs.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash
path="/weїrd, but gzýppéd"
file="/weird-gzipped"
time sudo apt-get install btrfs-tools -y
sudo dd if=/dev/zero of="/$file" bs=1 seek=3G count=1
sudo mkfs.btrfs -L a-disk "$file"
sudo mkdir -p "$path"
# sudo mount -t btrfs "$file" "$path" -o defaults,noatime,nodiratime,ssd,compress-force=zlib

function mount_without_Direct_IO() {
  sudo mount -t btrfs "$file" "$path" -o defaults,noatime,nodiratime,compress-force=zlib
}

losetup /dev/loop0 "$file" --direct-io=on
sudo mount -t btrfs /dev/loop0 "$path" -o defaults,noatime,nodiratime,compress-force=zlib
