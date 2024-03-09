#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/install-libssl-1.1.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
set -e
set -u
set -o pipefail

export TMPDIR="${TMPDIR:-/tmp}"
if [[ -z "${INSTALL_DIR:-}" ]]; then
  if [[ -d /usr/local/lib ]]; then INSTALL_DIR=/usr/local/lib; 
  elif [[ -d /usr/local/lib64 ]]; then INSTALL_DIR=/usr/local/lib64; 
  else 
    echo "Warning! Neigher /usr/local/lib nor /usr/local/lib64 exists. Creating /usr/local/lib"
    INSTALL_DIR=/usr/local/lib
    mkdir -p $INSTALL_DIR
  fi
fi

if [[ "$(uname -s)" != Linux ]]; then
  echo "A Linux OS is expected"
  exit 0
fi

function download_file() {
  local url="$1"
  local file="$2";
  local progress1="" progress2="" progress3="" 
  if [[ "${DOWNLOAD_SHOW_PROGRESS:-" != "True" ]] || [[ ! -t 1 ]]; then
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

function Install_LibSSL11() {
  local machine="$(uname -a)"
  local suffix="unknown";
  local long="$(getconf LONG_BIT)"
  if [[ "${machine:-}" =~ i?86 ]];    then suffix="linux-x86"; fi
  if [[ "${machine:-}" =~ aarch64 ]]; then 
    if [[ "${long:-}" == "32" ]]; then suffix="linux-arm"; else suffix="linux-arm64"; fi
  fi
  if [[ "${machine:-}" =~ armv ]];    then suffix="linux-arm"; fi
  if [[ "${machine:-}" =~ x86\_64 ]]; then 
    if [[ "${long:-}" == "32" ]]; then suffix="linux-x86"; else suffix="linux-x64"; fi
  fi

  url="https://raw.githubusercontent.com/devizer/KernelManagementLab/master/Dependencies/libssl-1.1-${suffix}.tar.xz"
  tmp="$(mktemp -d)"; test -n "$tmp" && tmp="$TMPDIR"
  file="$tmp/libssl-1.1-${suffix}.tar.xz"
  echo "Installing libssl 1.1.1m into $INSTALL_DIR"
  echo "Url is ${url}"
  echo "Download location is $file"
  download_file "$url" "$file"
  sudo tar xJf "$file" -C "$INSTALL_DIR"
  sudo ldconfig
}

Install_LibSSL11
