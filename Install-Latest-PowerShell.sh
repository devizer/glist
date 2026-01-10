#!/usr/bin/env bash
# export PSVER=7.4.12 PSDIR=/opt/pwsh
# url=https://raw.githubusercontent.com/devizer/glist/master/Install-Latest-PowerShell.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

function download_file() {
  local url="$1"
  local file="$2";
  local progress1="" progress2="" progress3="" 
  if [[ "$DOWNLOAD_SHOW_PROGRESS" != "True" ]] || [[ ! -t 1 ]]; then
    progress1="-q -nv"       # wget
    progress2="-s"           # curl
    progress3="--quiet=true" # aria2c
  fi
  local try1=""
  if [[ "$(command -v aria2c)" != "" ]]; then
    [[ -n "${try1:-}" ]] && try1="$try1 || "
    try1="aria2c $progress3 --allow-overwrite=true --check-certificate=false -s 9 -x 9 -k 4M -j 9 -d '$(dirname "$file")' -o '$(basename "$file")' '$url'"
  fi
  if [[ "$(command -v curl)" != "" ]]; then
    [[ -n "${try1:-}" ]] && try1="$try1 || "
    try1="${try1:-} curl $progress2 -f -kSL -o '$file' '$url'"
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

function Install_PowerShell() {
  local tmp="${TMPDIR:-/tmp}"
  PSDIR="${PSDIR:-/opt/pwsh}"
  if [[ -z "$PSVER" ]]; then
    local RawVer="$(Get-GitHub-Latest-Release PowerShell PowerShell)"
    PSVER="${RawVer#*v}";
  fi
  PSVER="${PSVER:-7.2.1}";
  # url depends on os and arch
  local system="$(uname -s)"
  local uname="$(uname -m)"
  local suf
  local ext="tar.gz"
  local isWindows="";
  if [[ "$system" == "Darwin" ]]; then
    suf=osx-x64; [[ "$uname" == arm* ]] && suf=osx-arm64 # x86_64 for intel
  elif [[ "$system" == "MSYS"* || "$system" == "MINGW"* ]]; then
    # todo: x86 | arm64
    suf="win-x64"
    ext="zip"
    isWindows=True;
  else
    # Linux?
    suf=linux-x64; 
    [[ "$uname" == aarch64 ]] && suf=linux-arm64
    [[ "$uname" == armv7* ]] && suf=linux-arm32
  fi
  local url="https://github.com/PowerShell/PowerShell/releases/download/v$PSVER/powershell-$PSVER-$suf.${ext}"
  local file="$(basename $url)"
  Say  "Downloading PowerShell [$PSVER] for [$(uname -m)] into [$PSDIR]"
  echo "       url: $url"
  echo "      file: $tmp/$file"
  # try-and-retry curl -kSL -o "$tmp/$file" "$url" || try-and-retry wget --no-check-certificate -O "$tmp/$file" "$url" || rm -f "$tmp/$file"
  DOWNLOAD_SHOW_PROGRESS=True
  download_file "$url" "$tmp/$file"
  sudo="sudo"; if [[ -z "$(command -v sudo)" ]] || [[ "$isWindows" == True ]]; then sudo=""; fi
  $sudo mkdir -p "$PSDIR"
  pushd $PSDIR >/dev/null
  if [[ -z "$isWindows" ]]; then
    if [[ -n "$(command -v pv)" ]]; then pv "$tmp/$file" | $sudo tar xzf -; else $sudo tar xzf "$tmp/$file"; fi
  else
    # todo: what if 7z is missing on windows
    7z x -bsp0 -bso0 -y "$tmp/$file"
  fi
  popd >/dev/null
  rm -f "$tmp/$file"
  sudo chmod +x "$PSDIR/pwsh" 2>/dev/null
  test -s "$PSDIR/pwsh" && sudo ln -f -s "$PSDIR/pwsh" /usr/local/bin/pwsh
  Say "PowerShell version: $(pwsh --version)"
}

Install_PowerShell
# TODO: Debian 8 - 6.0.5 is the latest ver