#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/install-libssl-1.1.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
set -e
set -u
set -o pipefail

INSTALL_DIR=""
NEED_REGISTRATION="False"
POS=First

while [ $# -gt 0 ]; do
  case "$1" in
    --target-folder)
      if [ -z "${2:-}" ]; then
        echo "Error: --target-folder requires a non-empty argument" >&2
        exit 1
      fi
      INSTALL_DIR="$2"
      shift 2
      ;;
    --register)
      NEED_REGISTRATION="True"
      shift 1
      ;;
    --first)
      POS="First"
      shift 1
      ;;
    --last)
      POS="Last"
      shift 1
      ;;
    *)
      shift
      ;;
  esac
done

sudo=$(command -v sudo || true)

export TMPDIR="${TMPDIR:-/tmp}"
if [[ -z "${INSTALL_DIR:-}" ]]; then
  if [[ -d /usr/local/lib ]]; then INSTALL_DIR=/usr/local/lib; 
  elif [[ -d /usr/local/lib64 ]]; then INSTALL_DIR=/usr/local/lib64;
  else 
    echo "Warning! Neigher /usr/local/lib nor /usr/local/lib64 exists. Creating /usr/local/lib"
    INSTALL_DIR=/usr/local/lib
    $sudo mkdir -p $INSTALL_DIR
  fi
fi

if [[ "$(uname -s)" != Linux ]]; then
  echo "A Linux OS is expected, platform is not supported"
  exit 0
fi

download_file() {
  local url="$1"
  local file="$2";
  local progress1="" progress2="" progress3="" 
  if [[ "${DOWNLOAD_SHOW_PROGRESS:-}" != "True" ]] || [[ ! -t 1 ]]; then
    progress1="-q -nv"       # wget
    progress2="-s"           # curl
    progress3="--quiet=true" # aria2c
  fi
  rm -f "$file" 2>/dev/null || rm -f "$file" 2>/dev/null || rm -f "$file"
  local try1=""
  if [[ "$(command -v aria2c)" != "" ]]; then
    [[ -n "${try1:-}" ]] && try1="$try1 || "
    try1="aria2c $progress3 --allow-overwrite=true --check-certificate=false -s 9 -x 9 -k 1M -j 9 -d '$(dirname "$file")' -o '$(basename "$file")' '$url'"
  fi
  if [[ "$(command -v curl)" != "" ]]; then
    [[ -n "${try1:-}" ]] && try1="$try1 || "
    try1="${try1:-} curl $progress2 -f -kfSL -o '$file' '$url'"
  fi
  if [[ "$(command -v wget)" != "" ]]; then
    [[ -n "${try1:-}" ]] && try1="$try1 || "
    try1="${try1:-} wget $progress1 --no-check-certificate -O '$file' '$url'"
  fi
  if [[ "${try1:-}" == "" ]]; then
    echo "error: niether curl, wget or aria2c is available"
    exit 42;
  fi
  eval $try1 || eval $try1 || eval $try1
  # eval try-and-retry wget $progress1 --no-check-certificate -O '$file' '$url' || eval try-and-retry curl $progress2 -kSL -o '$file' '$url'
}

Install_LibSSL11() {
  local machine="$(uname -a)"
  local suffix="unknown";
  local long="$(getconf LONG_BIT)"
  if [[ "${machine:-}" =~ i?86 ]];    then suffix="linux-x86"; fi
  if [[ "${machine:-}" =~ aarch64 ]]; then 
    if [[ "${long:-}" == "32" ]];     then suffix="linux-arm"; else suffix="linux-arm64"; fi
  fi
  if [[ "${machine:-}" =~ armv ]];    then suffix="linux-arm"; fi
  if [[ "${machine:-}" =~ x86\_64 ]]; then
    if [[ "${long:-}" == "32" ]];     then suffix="linux-x86"; else suffix="linux-x64"; fi
  fi

  url="https://raw.githubusercontent.com/devizer/KernelManagementLab/master/Dependencies/libssl-1.1-${suffix}.tar.xz"
  tmp="$(mktemp -d || true)"; test -z "$tmp" && tmp="$TMPDIR/download-libssl-1.1.1m-$RANDOM"
  file="$tmp/libssl-1.1-${suffix}.tar.xz"
  echo "Downloading libssl 1.1.1m binaries into '$INSTALL_DIR'"
  echo "Download url is '${url}', archive is '$file'"
  download_file "$url" "$file"
  $sudo mkdir -p "$INSTALL_DIR"
  $sudo tar xJf "$file" -C "$INSTALL_DIR"
  $sudo rm -rf "$tmp" || true
  $sudo sudo ldconfig || true

  if [[ "$NEED_REGISTRATION" == True ]]; then
    found=False
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "$INSTALL_DIR" ]]; then
            found=True
            break
        fi
    done < "/etc/ld.so.conf"
    
    if [[ "$found" == False ]]; then
      echo "Registering the '"$INSTALL_DIR"' folder as $POS line by ldconfig using /etc/ld.so.conf"
      conf=$(mktemp)
      if [[ "$POS" == First ]]; then
          (printf "$INSTALL_DIR\n"; cat /etc/ld.so.conf) > "$conf"
      else
          (cat /etc/ld.so.conf; printf "\n$INSTALL_DIR\n";) > "$conf"
      fi
      $sudo cp -v "$conf" /etc/ld.so.conf
      rm -f "$conf" || true
    fi
    $sudo ldconfig || true
    echo "Final libssl and libcrypto registed so-libraries"
    ldconfig -p | { grep "libssl\|libcrypto" || true; } || true
  fi
}

Conditional_Install_LibSSL11() {
  if [[ -n "$(command -v ldconfig)" ]]; then
    if [[ -z "$(ldconfig -p | grep libssl.so.1.1)" ]]; then
      echo "libssl.so.1.1 not found. Installing custom libssl 1.1"
      Install_LibSSL11
    else
      echo "Exists preinstalled libssl.so.1.1. Skipping installing custom libssl 1.1"  
    fi
  else
    echo "Messing ldconfig, platform is not supported"
  fi
}

Conditional_Install_LibSSL11
