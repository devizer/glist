#!/usr/bin/env bash
home=~
export VM_STORAGE="${VM_STORAGE:-$home/vm}"
export VM_USER="${VM_USER:-root}"
export VM_PASS="${VM_PASS:-pass}"
export VM_SSH_PORT="${VM_SSH_PORT:-2202}"
export VM_MEM=300M


function DownloadVM() {
  local vm_key="$1"
  if [[ "$vm_key" == "ARMv8" ]]; then
    files="ephemeral.qcow2 initrd.img vmlinuz Debian-10-arm64-final.qcow2 start-vm.sh"
    url_base="https://sourceforge.net/projects/debian-vm/files/ARMv8"
  elif [[ "$vm_key" == "ARMv7" ]]; then
    files="ephemeral.qcow2 initrd.img vmlinuz Debian-10-arm-final.qcow2 start-vm.sh"
    url_base="https://sourceforge.net/projects/debian-vm/files/ARMv7"
  else
    echo "vm build agent ERROR: VM [$vm_key] is not supported"
    return 1;
  fi

  local n;
  for n in $files; do
    local url="$url_base/$n/download"
    local full_name="$VM_STORAGE/$vm_key/$n"
    mkdir -p "$(dirname $full_name)"
    if [[ -s "$full_name.ok" ]] && [[ -s "$full_name" ]]; then
      echo "Already downloaded $full_name"
    else
      Say "
FROM: $url
  TO: $full_name"
      wget -q --show-progress --progress=dot:giga:force --no-check-certificate -O "$full_name" $url || curl -ksSL -o "$full_name" $url
      if [ $? -ne 0 ]; then
        rm -f "$full_name"
      else
        echo ok > "$full_name.ok"
      fi
    fi
  done
}

function ShutdownVM() {
  local vm_key="$1"
  Say "Shutdown $vm_key on port $VM_SSH_PORT"
  sshpass -p "${VM_PASS}" ssh -o StrictHostKeyChecking=no "${VM_USER}@127.0.0.1" -p "${VM_SSH_PORT}" shutdown now
}

function EvaluateCommand() {
  local cmd="$*"
  sshpass -p "${VM_PASS}" ssh -o StrictHostKeyChecking=no "${VM_USER}@127.0.0.1" -p "${VM_SSH_PORT}" bash -c "$cmd"
}

function RunVM() {
  local vm_key="$1"
  Say "Launching $vm_key on port $VM_SSH_PORT"
  VM_ROOT_FS=
  pushd "$VM_STORAGE/$vm_key"
  nohup bash start-vm.sh 1>&2 | tee nohup.out &
  local n=120
  while [ $n -gt 0 ]; do
    echo "Waiting for ssh connection to $vm_key on port $VM_SSH_PORT"
    sshpass -p "${VM_PASS}" ssh -o StrictHostKeyChecking=no "${VM_USER}@127.0.0.1" -p "${VM_SSH_PORT}" hostname
    local ok=$?;
    if [ $ok -eq 0 ]; then break; fi
    sleep 1
    n=$((n-1))
  done
  popd
  if [ $ok -ne 0 ]; then
    echo "vm build agent ERROR: VM is not responding via ssh"
    return 1;
  fi
  local mapto="$VM_STORAGE/$vm_key/fs"
  VM_ROOT_FS="$mapto"
  echo "SSH is ready"
  echo "Mapping root fs of the $vm_key to [$mapto]"
  mkdir -p "$mapto"
  echo "${VM_PASS}" | sshfs -o password_stdin root@localhost:/ -p "${VM_SSH_PORT}" "$mapto"
}

