#!/usr/bin/env bash
# dir="."; url=https://raw.githubusercontent.com/devizer/glist/master/bin/libMono.Unix.so/download-libMono-Unix-so.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash -s "$dir"

set -eu; set -o pipefail

machine=$(uname -m);
[[ $machine == x86_64 ]] && [[ "$(getconf LONG_BIT)" == "32" ]] && machine=i386
[[ $machine == aarch64 ]] && machine=arm64
[[ $machine == armv* ]] && machine=arm32v7
[[ "$(dpkg --print-architecture)" == armel ]] && machine=arm32v5

url="https://raw.githubusercontent.com/devizer/glist/master/bin/libMono.Unix.so/${machine}/libMono.Unix.so"
sofile=/tmp/libMono.Unix.so
echo "Downloading libMono.Unix.so for the current cpu arch
  url: $url
 file: $sofile"

curl -fkSL -o "$sofile" "$url" || curl -fkSL -o "$sofile" "$url" || curl -fkSL -o "$sofile" "$url"
echo "Downloaded $sofile:"
ls -la $sofile

dir="${1:-$(pwd)}"
echo "Searching Mono.Unix.dll in [$dir]"
find "$dir" -name "Mono.Unix.dll" | while read dllfile; do
  to="$(dirname "$dllfile")"
  echo "Copying libMono.Unix.so to [$to]"
  cp -fv "$sofile" "$to/libMono.Unix.so"
done
echo "Done. Below is results"
ls -la $(find "$dir" -name "*Mono.Unix*") # without quotes
