#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/Raid0-on-Azure-Pipelines-Linux.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
set -eu; set -o pipefail
if [[ "$(command -v Say)" == "" ]]; then
script=https://raw.githubusercontent.com/devizer/test-and-build/master/install-build-tools-bundle.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | TARGET_DIR=/usr/local/bin bash >/dev/null
Say --Reset-Stopwatch
fi

if [[ "$(uname -s)" != Linux ]] || [[ "$(Is-Microsoft-Hosted-Build-Agent)" = False ]] ; then
  echo "Skipping. Raid0-on-Microsoft-Hosted-Build-Agent.sh is supported on linux on microsoft hosted agent. Either devops pipeline or github actions."
  exit 0;
fi

Colorize() { 
   local str1st="${1:-}"
   str1st="${str1st,,}"
   local newLine="\n"
   if [[ "$str1st" == "--nonewline" ]] || [[ "$str1st" == "-nonewline" ]]; then newLine=""; shift; fi
   
   local NC='\033[0m' Color_White='\033[1;37m' Color_Black='\033[1;30m' \
         Color_Red='\033[1;31m' Color_Green='\033[1;32m' Color_Yellow='\033[1;33m' Color_Blue='\033[1;34m' Color_Magenta='\033[1;35m' Color_Cyan='\033[1;36m' \
         Color_LightRed='\033[0;31m' Color_LightGreen='\033[0;32m' Color_LightYellow='\033[0;33m' Color_LightBlue='\033[0;34m' Color_LightMagenta='\033[0;35m' Color_LightCyan='\033[0;36m' Color_LightWhite='\033[0;37m' \
         Color_Purple='\033[0;35m' Color_LightPurple='\033[1;35m'
   # local var="Color_${1:-}"
   # local color=""; [[ -n ${!var+x} ]] && color="${!var}"
   local color="$(eval "printf '%s' \"\$Color_${1:-}\"" 2>/dev/null)"
   shift || true
   printf "${color:-}$*${NC}${newLine}";
}


# ARGUMENTS
RAID_MODE="${RAID_MODE:-LINEAR}"
RAID_MODE=${RAID_MODE^^}
FREE_ROOT_SPACE_MB="${FREE_ROOT_SPACE_MB:-3000}"
FREE_SECOND_DRIVE_SPACE_MB="${FREE_SECOND_DRIVE_SPACE_MB:-500}"
LOOP_TYPE="${LOOP_TYPE:-0}"
LOOP_DIRECT_IO="${LOOP_DIRECT_IO:-off}"
FS="${FS:-BTRFS-Compressed}"
BTRFS_COMPRESS_MODE="${BTRFS_COMPRESS_MODE:-lzo}"
SECOND_DISK_MODE="${SECOND_DISK_MODE:-LOOP}"
COMPRESSION_OPTION=""; if [[ "$FS" == "BTRFS-Compressed" ]]; then COMPRESSION_OPTION=",compress-force=${BTRFS_COMPRESS_MODE:-lzo}"; fi
Colorize LightGreen "Raid0-on-Microsoft-Hosted-Build-Agent.sh Actual Arguments:"
Colorize LightGreen "     RAID_MODE: $RAID_MODE (Linear|RAID0)"
Colorize LightGreen "     FREE_ROOT_SPACE_MB: $FREE_ROOT_SPACE_MB"
Colorize LightGreen "     FREE_SECOND_DRIVE_SPACE_MB: $FREE_SECOND_DRIVE_SPACE_MB"
Colorize LightGreen "     LOOP_DIRECT_IO: $LOOP_DIRECT_IO (on|off)"
Colorize LightGreen "     FS: $FS (EXT2|EXT4|BTRFS|BTRFS-Compressed)"
Colorize LightGreen "     BTRFS_COMPRESS_MODE: $BTRFS_COMPRESS_MODE (lzo|zstd:1|..., only for compressed btrfs)"
Colorize LightGreen "     RESET_FOLDERS_TO_RAID (btrfs only): ${RESET_FOLDERS_TO_RAID:-}"




function Wrap-Cmd() {
    local cmd="$*"
    cmd="${cmd//[\/]/\∕}"
    cmd="${cmd//[:]/˸}"
    Say "$cmd"
    CMD_COUNT="${CMD_COUNT:-0}"
    CMD_COUNT=$((CMD_COUNT+1))
    local fileName="$SYSTEM_ARTIFACTSDIRECTORY/$(printf "%04u" "$CMD_COUNT") ${cmd}.log"
    eval "$@" |& tee "$fileName"
    LOG_FILE="$fileName"
}

if [[ -z "$(command -v jq)" ]] && [[ "$FS" = *"BTRFS"* ]]; then
  Say --Display-As=Error "Warning! jq is not found. docker data can not be moved to raid"
fi

Say "Creating raid"
echo VOLUMES
df -h 
echo;
echo DISKS
sudo fdisk -l

set +e
sdb_path="/dev/sdb"
sdb_path="$(sudo df | grep "/mnt" | awk '{print $1}' || true)"
echo "1) sdb_path = $sdb_path"
[[ -n "$sdb_path" ]] && sdb_path="${sdb_path::-1}"
echo "2) sdb_path = $sdb_path"
sda_path="/dev/sda"; [[ "$sdb_path" == "/dev/sda" ]] && sda_path="/dev/sdb";
echo "3) sdb_path = $sdb_path"
[[ -n "$sdb_path" ]] && Say "SECOND DISK /mnt disk: [${sdb_path}1]"
Say "ROOT DISK '/': ${sda_path}1"
sudo mount | grep "/ \|/mnt " || true
set -e

if [[ -f /mnt/swapfile ]]; then 
  echo; echo "SWAPOFF and DELETE /mnt/swapfile"
  sudo swapoff /mnt/swapfile || true
  sudo rm -f /mnt/swapfile || true
else
  echo "Missing /mnt/swapfile. New Image Detected"
fi

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
sudo cp -f /mnt/*.txt "$SYSTEM_ARTIFACTSDIRECTORY/" || true

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

function Setup-BTRFS-on-Root() {
    local freeSpace="$(Get-Free-Space-For-Directory-in-KB "/")"
    local size=$(((freeSpace-FREE_ROOT_SPACE_MB*1000)/1024))
    echo "FREE_ROOT_SPACE_MB: $FREE_ROOT_SPACE_MB MB, disk size: $size MB"
    if [[ -n "${EACH_DISK_SIZE:-}" ]]; then
      echo "Warning"
      echo "Maximum each disk size in raid is $size MB"
      echo "But it is overriden as ${EACH_DISK_SIZE:-}"
      size=${EACH_DISK_SIZE:-}
    fi
    # size=$((12*1025))
    Say "Creating loop-file '/disk-on-root' sized as ${size}M"
    sudo fallocate -l "${size}M" /disk-on-root
    sudo losetup --direct-io=${LOOP_DIRECT_IO:-off} /dev/loop22 /disk-on-root
    sudo losetup -a | grep "loop21\|loop22"
    # Wrap-Cmd sudo mdadm --zero-superblock --verbose --force /dev/loop{21,22}

    Say "Async creating 100Mb swap as '/mnt/swap100m'"
    nohup sudo bash -c "dd if=/dev/zero of=/mnt/swap100m bs=128K count=805; mkswap /mnt/swap100m; swapon /mnt/swap100m" &


    sudo mkdir -p /raid-${LOOP_TYPE}
    # wrap next two lines to parameters
    if [[ "$FS" == EXT2 ]]; then
      Wrap-Cmd sudo mkfs.ext2 /dev/loop22
      Wrap-Cmd sudo mount -o defaults,noatime,nodiratime /dev/loop22 /raid-${LOOP_TYPE}
    elif [[ "$FS" == EXT4 ]]; then
      Wrap-Cmd sudo mkfs.ext4 /dev/loop22
      Wrap-Cmd sudo mount -o defaults,noatime,nodiratime,commit=2000,barrier=0,data=writeback /dev/loop22 /raid-${LOOP_TYPE}
    elif [[ "$FS" == BTRFS ]]; then
      Wrap-Cmd sudo mkfs.btrfs -m single -d single -f -O ^extref,^skinny-metadata /dev/loop22
      Wrap-Cmd sudo mount -t btrfs /dev/loop22 /raid-${LOOP_TYPE} -o defaults,noatime,nodiratime,commit=2000,nodiscard,nobarrier
    elif [[ "$FS" == BTRFS-Compressed ]]; then
      # slower? 
      Wrap-Cmd sudo mkfs.btrfs -K -m single -d single -f -O ^extref,^skinny-metadata /dev/loop22
      Wrap-Cmd sudo mount -t btrfs /dev/loop22 /raid-${LOOP_TYPE} -o "defaults,noatime,nodiratime${COMPRESSION_OPTION},commit=2000,nodiscard,nobarrier"
    else
      echo "WRONG FS [$FS]. Aborting"
      exit 77
    fi
    Say "FREE SPACE AFTER MOUNTING of the RAID"
    sudo df -h -T
    sudo chown -R "$(whoami)" /raid-${LOOP_TYPE}
    # ls -la /raid-${LOOP_TYPE}

    Say "Setup BTRFS on /raid-${LOOP_TYPE} completed"
}

function Format_Thousand() {
  local num="$1"
  # LC_NUMERIC=en_US.UTF-8 printf "%'.0f\n" "$num" # but it is locale dependent
  # Next is locale independent version for positive integers
  awk -v n="$num" 'BEGIN { len=length(n); res=""; for (i=0;i<=len;i++) { res=substr(n,len-i+1,1) res; if (i > 0 && i < len && i % 3 == 0) { res = "," res } }; print res }' 2>/dev/null || echo "$num"
}

function Setup-Raid0-on-Loop() {
    FREE_ROOT_SPACE_MB="${FREE_ROOT_SPACE_MB:-3000}" # 1600 is not enough
    FREE_SECOND_DRIVE_SPACE_MB="${FREE_SECOND_DRIVE_SPACE_MB:-500}"
    RAID_MODE="${RAID_MODE:-LINEAR}"
    RAID_MODE=${RAID_MODE^^}
    # second
    local freeSpace="$(Get-Free-Space-For-Directory-in-KB "/mnt")"
    local freeSpaceAligned=$((freeSpace-FREE_SECOND_DRIVE_SPACE_MB))
    # root
    local freeSpaceOnRoot="$(Get-Free-Space-For-Directory-in-KB "/")"
    local freeSpaceOnRootAligned=$((freeSpaceOnRoot-FREE_ROOT_SPACE_MB*1000))

    # ok for RAID0
    local freeSpaceMin=$(( freeSpaceAligned < freeSpaceOnRootAligned ? freeSpaceAligned : freeSpaceOnRootAligned ))

    local sizeRoot
    local sizeSecond
    if [[ "$RAID_MODE" == LINEAR ]]; then 
      sizeRoot="$freeSpaceOnRootAligned"
      sizeSecond="$freeSpaceAligned"
    else
      sizeRoot="$freeSpaceMin"
      sizeSecond="$freeSpaceMin"
    fi

    echo "Free Space on the Second Drive '/mnt' = $(Format_Thousand "$freeSpace") Kb, allowed = $(Format_Thousand "$freeSpaceAligned") Kb"
    echo "Free Space on the Root Drive '/' =  $(Format_Thousand "$freeSpaceOnRoot") Kb, allowed = $(Format_Thousand "$freeSpaceOnRootAligned") Kb"

    local size=$((freeSpaceMin/1024))
    if [[ -n "${EACH_DISK_SIZE:-}" ]]; then
      echo "Warning"
      echo "Maximum each disk size in raid is $size MB"
      echo "But it is overriden as ${EACH_DISK_SIZE:-}"
      size=${EACH_DISK_SIZE:-}
    fi
    echo "Each Raid Drive Size: $(Format_Thousand "$size") MB"
    # size=$((12*1025))
    if [[ "$SECOND_DISK_MODE" == "LOOP" ]]; then
      Say "Creating loop-file '/mnt/disk-on-mnt' sized as ${sizeSecond}M"
      sudo fallocate -l "${size}M" /mnt/disk-on-mnt
      sudo losetup --direct-io=${LOOP_DIRECT_IO:-off} /dev/loop21 /mnt/disk-on-mnt
      second_raid_disk="/dev/loop21"
    else
      second_raid_disk="${sdb_path}2"
    fi
    Say "Creating loop-file '/disk-on-root' sized as ${size}M"
    sudo fallocate -l "${sizeRoot}M" /disk-on-root
    sudo losetup --direct-io=${LOOP_DIRECT_IO:-off} /dev/loop22 /disk-on-root
    sudo losetup -a | grep "loop21\|loop22"
    # Wrap-Cmd sudo mdadm --zero-superblock --verbose --force /dev/loop{21,22}

    Say "Async creating 100Mb swap as '/mnt/swap100m'"
    nohup sudo bash -c "dd if=/dev/zero of=/mnt/swap100m bs=128K count=805; mkswap /mnt/swap100m; swapon /mnt/swap100m" &


    # Wrap-Cmd sudo fdisk -l BLOCK ONLY
    Say "mdadm --create ..."
    local argLevel="linear"; [[ "$RAID_MODE" == LINEAR ]] && argLevel="0"
    local err=0
    yes | sudo mdadm --create /dev/md0 --chunk=128 --level=$argLevel --raid-devices=2 "$second_raid_disk" /dev/loop22 || err=$?
    if [[ $? -eq 0 ]]; then
      Say "Success: mdadm --create"
    elif [[ $? -eq 141 ]]; then
      Say "Warning! Exit code 141 by mdadm --create, but ok"
    else
      Say --Display-As=Error "mdadm --create failed. Exit Code [$err]"
      exit $err
    fi

    # sleep 1
    Wrap-Cmd sudo mdadm --detail /dev/md0

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
      Wrap-Cmd sudo mount -t btrfs /dev/md0 /raid-${LOOP_TYPE} -o "defaults,noatime,nodiratime${COMPRESSION_OPTION},commit=2000,nodiscard,nobarrier"
    else
      echo "WRONG FS [$FS]. Aborting"
      exit 77
    fi
    Say "FREE SPACE AFTER MOUNTING of the RAID"
    sudo df -h -T
    sudo chown -R "$(whoami)" /raid-${LOOP_TYPE}
    # ls -la /raid-${LOOP_TYPE}

    Say "Setup-Raid0 on /raid-${LOOP_TYPE} completed"
    
}

# Wrap-Cmd sudo cat /etc/mdadm/mdadm.conf
if [[ -n "$sdb_path" ]]; then
  Setup-Raid0-on-Loop
  theDevice="/dev/md0"
else
  Setup-BTRFS-on-Root
  # theRoot="/dev/loop22"
  theDevice="/dev/loop22"
fi
theRoot="/raid-${LOOP_TYPE}"

if [[ -n "${MOVE_DOCKER_TO_RAID:-}" ]]; then
  err=""
  docker_data=""
  if [[ "${FS:-}" != *"BTRFS"* ]]; then 
    # TODO: Create sub-volume /docker if BTRFS or BTRFS-Compressed
    docker_data="/raid-${LOOP_TYPE}/docker-file-system"
    echo "Moving docker to the raid as folder '$docker_data' ..."
    sudo mkdir -p "/raid-${LOOP_TYPE}/docker-file-system"
  else
    docker_data="/docker"
    echo "Create docker-data subvolume for $docker_data folder ..."
    sudo mkdir -p "$docker_data"
    sudo btrfs subvolume create /raid-${LOOP_TYPE}/docker-data
    # sudo mount -t btrfs "$theRoot" "$docker_data" -o "defaults,noatime,nodiratime${COMPRESSION_OPTION},commit=2000,nodiscard,nobarrier,subvol=docker-data"
    sudo mount -t btrfs "$theDevice" "$docker_data" -o "defaults,noatime,nodiratime${COMPRESSION_OPTION},commit=2000,nodiscard,nobarrier,subvol=docker-data"
  fi
  # cat /etc/docker/daemon.json
  sudo systemctl stop docker
  tmp="$(mktemp)"
  echo "Apply .data-root='$docker_data' for docker daemon config"
  if [[ ! -f /etc/docker/daemon.json ]]; then echo '{}' | sudo tee /etc/docker/daemon.json >/dev/null; fi
  jq '."data-root" = "'"$docker_data"'"' /etc/docker/daemon.json > "$tmp" && sudo mv -f "$tmp" /etc/docker/daemon.json || err="fail"
  # cat /etc/docker/daemon.json
  sudo systemctl start docker || err="fail"
  if [[ -n "${err:-}" ]]; then
    Say --Display-As=Error "Docker start failed"
    sudo systemctl status docker.service
    sudo journalctl -u docker.service -b | cat
  else
    Say "Docker data successfully moved to the '$docker_data' on raid"
  fi
fi

# RESET_FOLDERS_TO_RAID="/tmp;/var/a b c/d/e;"
if [[ "${FS:-}" == *"BTRFS"* ]]; then
echo "${RESET_FOLDERS_TO_RAID:-}" | awk -F';' '{ for(i=1; i<=NF; ++i) print $i; }' | while IFS='' read -r folder; do if [[ -n "$folder" ]]; then
  sv="${folder//[\/]/-}"; sv="${sv//[:]/-}"; sv="${sv//[\ ]/-}"
  sv="${sv#"${sv%%[!\-]*}"}"   # remove leading "-" characters
  # sv="${sv##*(-)}" - also works
  sudo mkdir -p "$folder"
  chmod="$(sudo stat --format '%a' "$folder")"
  uowner="$(sudo stat -c '%U' "$folder")"
  gowner="$(sudo stat -c '%G' "$folder")"
  nohup sudo rm -rf "$folder"/* &
  Say "Creating subvolume [/raid-${LOOP_TYPE}/$sv] for '$folder' (chmod is '$chmod', owner is '$uowner:$gowner')"
  # sudo btrfs subvolume create /raid-${LOOP_TYPE}/${sv}
  sudo btrfs subvolume create "/raid-${LOOP_TYPE}/${sv}"
  echo "Subvolume '${sv}' successfully created. Mounting ..."
  # sudo btrfs subvolume list /raid-${LOOP_TYPE} | sort
  # echo "DO NOT RM /raid-${LOOP_TYPE}/${sv} ????"
  # sudo rm -rf "/raid-${LOOP_TYPE}/${sv}"
  # size="$(sudo du -h -d 0 "$folder" | awk '{print $1}')"; echo "Original size: '$size'"
  sudo mount -t btrfs "$theDevice" "$folder" -o "defaults,noatime,nodiratime${COMPRESSION_OPTION},commit=2000,nodiscard,nobarrier,subvol=${sv}"
  test -n "$chmod" && sudo chmod -R "$chmod" "$folder"
  sudo chown -R "$(whoami)" "$folder"
  chmod="$(sudo stat --format '%a' "$folder")"
  if [[ -n "$uowner" ]] && [[ -n "$gowner" ]]; then sudo chown "$uowner:$gowner" "$folder" || true; fi
  uowner="$(sudo stat -c '%U' "$folder")"
  gowner="$(sudo stat -c '%G' "$folder")"
  echo "Subvolume '${sv}' successfully mounted as '${folder}', actual chmod is '$chmod', actual owner is '$uowner:$gowner'"
fi; done
else
  if [[ -n "${RESET_FOLDERS_TO_RAID:-}" ]]; then
    Say --Display-As=Error "Unable to reset folders '${RESET_FOLDERS_TO_RAID:-}' to raid. It is supported on BTRFS or BTRFS-Compressed file system"
  fi
fi

Say "FINAL VOLUMES"
sudo df -h -T
