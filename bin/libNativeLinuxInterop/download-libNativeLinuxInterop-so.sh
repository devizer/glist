#!/usr/bin/env bash
# dir="."; url=https://raw.githubusercontent.com/devizer/glist/master/bin/libNativeLinuxInterop/download-libNativeLinuxInterop-so.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash -s "$dir"

set -eu; set -o pipefail
machine=$(uname -m);
[[ $machine == x86_64 ]] && [[ "$(getconf LONG_BIT)" == "32" ]] && machine=linux-x86
[[ $machine == aarch64 ]] && machine=linux-arm64
[[ $machine == armv* ]] && machine=linux-arm
[[ "$(dpkg --print-architecture)" == armel ]] && machine=linux-armel
if [[ -e /etc/redhat-release ]]; then
  redhatRelease=$(</etc/redhat-release)
  if [[ $redhatRelease == "CentOS release 6."* || $redhatRelease == "Red Hat Enterprise Linux Server release 6."* ]]; then
    machine=linux-rhel.6-x64
  fi
fi

url="https://raw.githubusercontent.com/devizer/glist/master/bin/libNativeLinuxInterop/${machine}/libNativeLinuxInterop.so"
sofile=/tmp/libNativeLinuxInterop.so
echo "Downloading libNativeLinuxInterop.so for the current cpu arch [$machine]
  url: $url
 file: $sofile"

curl -fkSL -o "$sofile" "$url" || curl -fkSL -o "$sofile" "$url" || curl -fkSL -o "$sofile" "$url"
echo "Downloaded $sofile:"
ls -la $sofile

dir="${1:-$(pwd)}"
echo "Searching Universe.LinuxTaskStats.dll in [$dir]"
find "$dir" -name "Universe.LinuxTaskStats.dll" | while read dllfile; do
  to="$(dirname "$dllfile")"
  echo "Copying libNativeLinuxInterop.so to [$to]"
  cp -fv "$sofile" "$to/libNativeLinuxInterop.so"
done
echo "Done. Below is results"
ls -la $(find "$dir" -name "libNativeLinuxInterop.so") # without quotes
