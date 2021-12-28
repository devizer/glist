#!/usr/bin/env bash
# export DCVER=2.2.2 DCDIR=/usr/local/bin
# url=https://raw.githubusercontent.com/devizer/glist/master/Install-Latest-Docker-Compose.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

function Install_Docker_Compose() {
  local tmp="${TMPDIR:-/tmp}"
  DCDIR="${DCDIR:-/opt/pwsh}"
  if [[ -z "$DCVER" ]]; then
    local RawVer="$(Get-GitHub-Latest-Release docker compose)"
    DCVER="${RawVer#*v}";
  fi
  DCVER="${DCVER:-2.2.2}";
  # url depends on os and arch
  local system="$(uname -s)"
  local uname="$(uname -m)"
  local suf
  if [[ "$system" == "Darwin" ]]; then
    suf=darwin-x86_64; [[ "$uname" == arm* ]] && suf=darwin-aarch64 # x86_64 for intel
  else
    # Linux?
    suf=linux-x86_64; 
    [[ "$uname" == aarch64 ]] && suf=linux-aarch64; 
    [[ "$uname" == armv7* ]] && suf=linux-armv7
    [[ "$uname" == armv6* ]] && suf=linux-armv6
  fi
  local url="https://github.com/docker/compose/releases/download/v$DCVER/docker-compose-$suf"
  local file="$DCDIR/docker-compose"
  Say  "Downloading Docker Compose [$DCVER] for [$uname] into [$DCDIR]"
  echo "       url: $url"
  echo "      file: $tmp/$file"
  try-and-retry curl -kSL -o "$tmp/$file" "$url" || try-and-retry wget --no-check-certificate -O "$tmp/$file" "$url" || rm -f "$tmp/$file"
  sudo mkdir -p "$DCDIR"
  sudo mv -f "$tmp/$file" "$DCDIR/docker-compose"
  rm -f "$tmp/$file" 2>/dev/null
  sudo chmod +x "$DCDIR/docker-compose" 2>/dev/null
  Say "docker-compose version: $(docker-compose --version)"
}

Install_Docker_Compose
