#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/Raid0-on-Azure-Pipelines-Linux.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
set -eu; set -o pipefail
if [[ "$(command -v Say)" == "" ]]; then
script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-build-tools-bundle.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | TARGET_DIR=/usr/local/bin bash >/dev/null
Say --Reset-Stopwatch
fi

LOOP_TYPE="${LOOP_TYPE:-0}"
FS="${FS:-BTRFS-Compressed}"
CMD_COUNT=0

function Wrap-Cmd() {
    local cmd="$*"
    cmd="${cmd//[\/]/\∕}"
    cmd="${cmd//[:]/˸}"
    Say "$cmd"
    CMD_COUNT=$((CMD_COUNT+1))
    local fileName="$SYSTEM_ARTIFACTSDIRECTORY/$(printf "%04u" "$CMD_COUNT") ${cmd}.log"
    eval "$@" |& tee "$fileName"
    LOG_FILE="$fileName"
}

sdb_path="/dev/sdb"
sdb_path="$(sudo df | grep "/mnt" | awk '{print $1}')"
sdb_path="${sdb_path::-1}"
sda_path="/dev/sda"; [[ "$sdb_path" == "/dev/sda" ]] && sda_path="/dev/sdb";
Say "/mnt disk: [${sdb_path}1]; / (the root) disk: ${sda_path}1"
sudo mount

sudo swapoff /mnt/swapfile
sudo rm -f /mnt/swapfile

Say "sudo fdisk -l"
sudo fdisk -l
Say "sudo df -h -T"
sudo df -h -T

function Reset-Sdb-Disk() {
    Say "Reset-Sdb-Disk [$sdb_path]"
    Drop-FS-Cache
    Say "sudo umount /mnt"
    sudo umount /mnt
    Say "Execute fdisk"
    echo "d
n
p
1

+100M
n
p
2


w
" | sudo fdisk "${sdb_path}"

    Say "fdisk -l ${sdb_path}"
    sudo fdisk -l ${sdb_path}
    sleep 1
    sudo mkswap -f "${sdb_path}1" || true # DEBUG ONLY
    sudo swapon -f "${sdb_path}1" || true # DEBUG ONLY
    Say "swapon"
    sudo swapon
    sdb2size="$(sudo fdisk -l ${sdb_path} | grep "${sdb_path}2" | awk '{printf "%5.0f\n", ($3-$2)/2}')"
    Say "sdb2size: [$sdb2size] KB"

}

# Say "apt-get install util-linux fio"
# sudo apt-get install util-linux fio tree -y -qq >/dev/null
Wrap-Cmd sudo tree -a -h -u /mnt
Wrap-Cmd sudo swapon
sudo cp -f /mnt/*.txt "$SYSTEM_ARTIFACTSDIRECTORY/"

function Get-Free-Space-For-Directory-in-KB() {
    local dir="${1}"
    pushd "$dir" >/dev/null
      df -P . | tail -1 | awk '{print $4}'
    popd >/dev/null
}

function Get-Working-Set-for-Directory-in-KB() {
    local dir="${1}"
    local freeSpace="$(Get-Free-Space-For-Directory-in-KB "$dir")"
    local maxKb=$((freeSpace - 500*1000))
    local ret=$((16*1024*1024))
    if [[ "$ret" -gt "$maxKb" ]]; then ret="$maxKb"; fi
    echo "$ret";
}

function Setup-Raid0-on-Loop() {
    local freeSpace="$(Get-Free-Space-For-Directory-in-KB "/mnt")"
    local size=$(((freeSpace-500*1000)/1024))
    size=$((12*1025))
    if [[ "$SECOND_DISK_MODE" == "LOOP" ]]; then
      Wrap-Cmd sudo fallocate -l "${size}M" /mnt/disk-on-mnt
      Wrap-Cmd sudo losetup --direct-io=${LOOP_DIRECT_IO} /dev/loop21 /mnt/disk-on-mnt
      second_raid_disk="/dev/loop21"
    else
      second_raid_disk="${sdb_path}2"
    fi
    Wrap-Cmd sudo fallocate -l "${size}M" /disk-on-root
    Wrap-Cmd sudo losetup --direct-io=${LOOP_DIRECT_IO} /dev/loop22 /disk-on-root
    Wrap-Cmd sudo losetup -a
    Wrap-Cmd sudo losetup -l
    # Wrap-Cmd sudo mdadm --zero-superblock --verbose --force /dev/loop{21,22}

    Wrap-Cmd sudo fdisk -l 
    Say "mdadm --create ..."
    yes | sudo mdadm --create /dev/md0 --chunk=32 --level=0 --raid-devices=2 "$second_raid_disk" /dev/loop22 || true
    local err=$?
    if [[ $? -eq 0 ]]; then
      Say "Success: mdadm --create"
    elif [[ $? -eq 141 ]]; then
      Say "Warning 141 by mdadm --create, but ok"
    else
      Say --Display-As=Error "mdadm --create failed. Exit Code [$err]"
      exit $err
    fi

    sleep 1
    Wrap-Cmd sudo mdadm --detail /dev/md0

    Say "sudo mkfs.btrfs /dev/md0; and mount"
    Wrap-Cmd sudo mkdir -p /raid-${LOOP_TYPE}
    # wrap next two lines to parameters
    if [[ "$FS" == EXT2 ]]; then
      Wrap-Cmd sudo mkfs.ext2 /dev/md0
      Wrap-Cmd sudo mount -o defaults,noatime,nodiratime /dev/md0 /raid-${LOOP_TYPE}
    elif [[ "$FS" == EXT4 ]]; then
      Wrap-Cmd sudo mkfs.ext4 /dev/md0
      Wrap-Cmd sudo mount -o defaults,noatime,nodiratime,commit=2000,barrier=0,data=writeback /dev/md0 /raid-${LOOP_TYPE}
    elif [[ "$FS" == BTRFS ]]; then
      Wrap-Cmd sudo mkfs.btrfs -m single -d single -f -O ^extref,^skinny-metadata /dev/md0
      Wrap-Cmd sudo mount -t btrfs /dev/md0 /raid-${LOOP_TYPE} -o defaults,noatime,nodiratime,commit=2000,nodiscard,nobarrier
    elif [[ "$FS" == BTRFS-Compressed ]]; then
      # slower? 
      Wrap-Cmd sudo mkfs.btrfs -m single -d single -f -O ^extref,^skinny-metadata /dev/md0
      Wrap-Cmd sudo mount -t btrfs /dev/md0 /raid-${LOOP_TYPE} -o defaults,noatime,nodiratime,compress-force=lzo:1,commit=2000,nodiscard,nobarrier
    else
      echo "WRONG FS [$FS]"
      exit 77
    fi
    Say "FREE SPACE AFTER MOUNTING of the RAID"
    Wrap-Cmd sudo df -h -T
    Wrap-Cmd sudo chown -R "$(whoami)" /raid-${LOOP_TYPE}
    Wrap-Cmd ls -la /raid-${LOOP_TYPE}
    Wrap-Cmd sudo df -h -T

    Say "Setup-Raid0 as ${LOOP_TYPE} loop complete"
    
}

Wrap-Cmd sudo cat /etc/mdadm/mdadm.conf
Setup-Raid0-on-Loop

if [[ -n "${MOVE_DOCKER_TO_RAID:-}" ]]; then
  echo "Moving docker to the raid ..."
  sudo mkdir -p "/raid-${LOOP_TYPE}/docker"
  cat /etc/docker/daemon.json
  docker image ls
  docker ps -a
  sudo systemctl stop docker
  tmp="$(mktemp)";
  echo "Apply .experimental for docker"
  jq '.experimental = "enabled"' /etc/docker/daemon.json > "$tmp" && sudo mv -f "$tmp" /etc/docker/daemon.json
  # echo "Apply .data-root for docker (v2)"
  # jq '."data-root" = "/raid-'${LOOP_TYPE}'/docker"' /etc/docker/daemon.json > "$tmp" && sudo mv -f "$tmp" /etc/docker/daemon.json
  cat /etc/docker/daemon.json
  sudo systemctl start docker || { sudo systemctl status docker.service; }
  sudo journalctl -u docker.service -b | cat
  Say "Docker successfully moved to the raid"
  docker image ls
fi
