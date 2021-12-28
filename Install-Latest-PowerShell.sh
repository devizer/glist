#!/usr/bin/env bash
# export PSVER=7.2.1 PSDIR=/opt/pwsh
# url=https://raw.githubusercontent.com/devizer/glist/master/Install-Latest-PowerShell.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

function Install_PowerShell() {
  local tmp="${TMPDIR:-/tmp}"
  PSDIR="${PSDIR:-/opt/pwsh}"
  if [[ -z "$PSVER" ]]; then
    local RawVer="$(Get-GitHub-Latest-Release PowerShell PowerShell)"
    PSVER="${RawVer#*v}";
  fi
  PSVER="${PSVER:-7.2.1}";
  local suf=linux-x64; [[ "$(uname -m)" == aarch64 ]] && suf=linux-arm64; [[ "$(uname -m)" == armv7* ]] && suf=linux-arm32
  # osx
  local System="${System:-$(uname -s)}"
  local uname="$(uname -m)"
  if [[ "$System" == "Darwin" ]]; then
    suf=osx-x64; [[ "$uname" == arm* ]] && suf=osx-arm64 # x86_64 for intel
  else
    # Linux?
    suf=linux-x64; [[ "$uname" == aarch64 ]] && suf=linux-arm64; [[ "$uname" == armv7* ]] && suf=linux-arm32
  fi
  local url="https://github.com/PowerShell/PowerShell/releases/download/v$PSVER/powershell-$PSVER-$suf.tar.gz"
  local file="$(basename $url)"
  Say  "Downloading PowerShell [$PSVER] for [$(uname -m)] into [$PSDIR]"
  echo "       url: $url"
  echo "      file: $tmp/$file"
  try-and-retry wget --no-check-certificate -O "$tmp/$file" "$url" || try-and-retry curl -kSL -o "$tmp/$file" "$url" || rm -f "$tmp/$file"
  sudo mkdir -p "$PSDIR"
  pushd $PSDIR >/dev/null
  if [[ -n "$(command -v pv)" ]]; then pv "$tmp/$file" | sudo tar xzf -; else sudo tar xzf "$tmp/$file"; fi
  popd >/dev/null
  rm -f "$tmp/$file"
  test -s "$PSDIR/pwsh" && sudo ln -f -s "$PSDIR/pwsh" /usr/local/bin/pwsh
  Say "PowerShell version: $(pwsh --version)"
}

Install_PowerShell
