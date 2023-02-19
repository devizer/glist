#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/Raid0-on-Azure-Pipelines-Linux.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
set -eu; set -o pipefail
if [[ "$(command -v Say)" == "" ]]; then
script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-build-tools-bundle.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | TARGET_DIR=/usr/local/bin bash >/dev/null
Say --Reset-Stopwatch
fi

if [[ "$(uname -s)" != Linux ]]; then
  echo "Skipping. Raid0-on-Azure-Pipelines-Linux.sh is supported on linux on microsoft hosted agent"
  exit 0;
fi

SECOND_DISK_MODE="${SECOND_DISK_MODE:-LOOP}"
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
sudo mount | grep "/ \|/mnt "

sudo swapoff /mnt/swapfile
sudo rm -f /mnt/swapfile

function Create-New-Swap() {
  sudo dd if=/dev/zero of=/mnt/swap100m bs=128K count=782
  sudo mkswap /mnt/swap100m
  sudo swapon /mnt/swap100m
}
# Create-New-Swap &


Say "sudo fdisk -l"
sudo fdisk -l | grep "Disk /dev/sd"
Say "sudo df -h -T"
sudo df -h -T | grep -E "(/|/mnt)$"

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
    Say "Creating swap on '${sdb_path}1' (v2)"
    sudo mkswap -f "${sdb_path}1" || true # DEBUG ONLY
    sudo swapon "${sdb_path}1" || true # DEBUG ONLY
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
    # size=$((12*1025))
    if [[ "$SECOND_DISK_MODE" == "LOOP" ]]; then
      Say "Creating loop-file '/mnt/disk-on-mnt' sized as ${size}M"
      sudo fallocate -l "${size}M" /mnt/disk-on-mnt
      sudo losetup --direct-io=${LOOP_DIRECT_IO} /dev/loop21 /mnt/disk-on-mnt
      second_raid_disk="/dev/loop21"
    else
      second_raid_disk="${sdb_path}2"
    fi
    Say "Creating loop-file '/disk-on-root' sized as ${size}M"
    sudo fallocate -l "${size}M" /disk-on-root
    sudo losetup --direct-io=${LOOP_DIRECT_IO} /dev/loop22 /disk-on-root
    sudo losetup -a | grep "loop21\|loop22"
    # Wrap-Cmd sudo mdadm --zero-superblock --verbose --force /dev/loop{21,22}

    Say "Async creating 100Mb swap as '/mnt/swap100m'"
    nohup sudo bash -c "dd if=/dev/zero of=/mnt/swap100m bs=128K count=805; mkswap /mnt/swap100m; swapon /mnt/swap100m" &


    # Wrap-Cmd sudo fdisk -l BLOCK ONLY
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

    Say "SKIPPING SLEEEEEEEEEEEEEEEEEP"
    # sleep 1
    Wrap-Cmd sudo mdadm --detail /dev/md0

    Say "sudo mkfs.btrfs /dev/md0; and mount"
    sudo mkdir -p /raid-${LOOP_TYPE}
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
      Wrap-Cmd sudo mkfs.btrfs -K -m single -d single -f -O ^extref,^skinny-metadata /dev/md0
      Wrap-Cmd sudo mount -t btrfs /dev/md0 /raid-${LOOP_TYPE} -o "defaults,noatime,nodiratime,compress-force=lzo:1,commit=2000,nodiscard,nobarrier"
    else
      echo "WRONG FS [$FS]"
      exit 77
    fi
    Say "FREE SPACE AFTER MOUNTING of the RAID"
    sudo df -h -T
    sudo chown -R "$(whoami)" /raid-${LOOP_TYPE}
    # ls -la /raid-${LOOP_TYPE}

    Say "Setup-Raid0 on /raid-${LOOP_TYPE} completed"
    
}

# Wrap-Cmd sudo cat /etc/mdadm/mdadm.conf
Setup-Raid0-on-Loop

if [[ -n "${MOVE_DOCKER_TO_RAID:-}" ]]; then
  err=""
  echo "Moving docker to the raid ..."
  sudo mkdir -p "/raid-${LOOP_TYPE}/docker-file-system"
  # cat /etc/docker/daemon.json
  sudo systemctl stop docker
  tmp="$(mktemp)"
  echo "Apply .data-root='/raid-${LOOP_TYPE}/docker-file-system' for docker daemon config"
  jq '."data-root" = "/raid-'${LOOP_TYPE}'/docker-file-system"' /etc/docker/daemon.json > "$tmp" && sudo mv -f "$tmp" /etc/docker/daemon.json || err="fail"
  # cat /etc/docker/daemon.json
  sudo systemctl start docker || err="fail"
  if [[ -n "${err:-}" ]]; then
    Say --Display-As=Error "Docker start failed"
    sudo systemctl status docker.service
    sudo journalctl -u docker.service -b | cat
  else
    Say "Docker data successfully moved to the /raid-${LOOP_TYPE}/docker-file-system on raid"
  fi
fi

# RESET_FOLDERS_TO_RAID="/tmp;/var/a b c/d/e;"
if [[ "$FS" == *"BTRFS"* ]]; then
echo "${RESET_FOLDERS_TO_RAID:-}" | awk -F';' '{ for(i=1; i<=NF; ++i) print $i; }' | while IFS='' read -r folder; do if [[ -n "$folder" ]]; then
  sv="${folder//[\/]/-}"; sv="${sv//[:]/-}"; sv="${sv//[\ ]/-}"
  sv="${sv#"${sv%%[!\-]*}"}"   # remove leading "-" characters
  # sv="${sv##*(-)}" - also works
  Say "Create subvolume vNew [/raid-${LOOP_TYPE}/$sv] for '$folder'"
  sudo mkdir -p "$folder"
  sudo btrfs subvolume create /raid-${LOOP_TYPE}/${sv}
  echo subvolume created. Mounting ...
  # sudo btrfs subvolume list /raid-${LOOP_TYPE} | sort
  # echo "DO NOT RM /raid-${LOOP_TYPE}/${sv} ????"
  # sudo rm -rf "/raid-${LOOP_TYPE}/${sv}"
  # size="$(sudo du -h -d 0 "$folder" | awk '{print $1}')"; echo "Original size: '$size'"
  sudo mount -t btrfs /dev/md0 "$folder" -o "defaults,noatime,nodiratime,compress-force=lzo:1,commit=2000,nodiscard,nobarrier,subvol=${sv}"
  sudo chown -R "$(whoami)" "$folder"
fi; done
fi
