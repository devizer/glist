#!/usr/bin/env bash
# V1
# file=/usr/local/bin/DevOps-Lib.sh; sudo mkdir -p "$(dirname "$file")"; url=https://raw.githubusercontent.com/devizer/glist/master/DevOps-Lib.sh; (wget -q -nv --no-check-certificate -O "$file" $url 2>/dev/null || curl -o "$file" -ksSL $url); . $file; printf "\n\ntest -f $file && . $file" >> ~/.bashrc
set -eu; set -o pipefail

# Include Directive: [ ..\Includes\*.sh ]
# Include File: [\Includes\download_file.sh]
function download_file() {
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
    echo "error: niether curl, wget or aria2c is available" >&2
    exit 42;
  fi
  eval $try1 || eval $try1 || eval $try1
  # eval try-and-retry wget $progress1 --no-check-certificate -O '$file' '$url' || eval try-and-retry curl $progress2 -kSL -o '$file' '$url'
}

# Include File: [\Includes\download_file_failover.sh]
function download_file_failover() {
  local file="$1"
  shift
  for url in "$@"; do
    # DEBUG: echo -e "\nTRY: [$url] for [$file]"
    local err=0;
    download_file "$url" "$file" || err=$?
    # DEBUG: say Green "Download status for [$url] is [$err]"
    if [ "$err" -eq 0 ]; then return; fi
  done
  return 55;
}

# Include File: [\Includes\find_decompressor.sh]
function find_decompressor() {
  COMPRESSOR_EXT=""
  COMPRESSOR_EXTRACT=""
  local force_gzip_priority="$(To_Boolean "Env Var FORCE_GZIP_PRIORITY", "${FORCE_GZIP_PRIORITY:-}")"
  if [[ "$force_gzip_priority" == True ]]; then
    if [[ "$(command -v gzip)" != "" ]]; then
      COMPRESSOR_EXT=gz
      COMPRESSOR_EXTRACT="gzip -f -d"
    elif [[ "$(command -v xz)" != "" ]]; then
      COMPRESSOR_EXT=xz
      COMPRESSOR_EXTRACT="xz -f -d"
    fi
  else
    if [[ "$(command -v xz)" != "" ]]; then
      COMPRESSOR_EXT=xz
      COMPRESSOR_EXTRACT="xz -f -d"
    elif [[ "$(command -v gzip)" != "" ]]; then
      COMPRESSOR_EXT=gz
      COMPRESSOR_EXTRACT="gzip -f -d"
    fi
  fi
}

# Include File: [\Includes\Find_Hash_Algorithm.sh]
function Find_Hash_Algorithm() {
  local alg
  local algs="${EXISTING_HASH_ALGORITHMS:-sha512 sha384 sha256 sha224 sha1 md5}"
  if [[ "$(Get_OS_Platform)" == MacOS ]]; then
    local file="$(MkTemp-File-Smarty "hash.txt" "hfv")"
    printf "%s" "hash" > "$file"
    for alg in $algs; do
      local hash="$(Get_Hash_Of_File "$alg" "$file")"
      if [[ -n "$hash" ]]; then echo "$alg"; break; fi
    done
    rm -f "$file"
    return;
  fi
  for alg in $algs; do
    if [[ "$(command -v ${alg}sum)" != "" ]]; then
      echo $alg
      return;
    fi
  done
}

function Get_Hash_Of_File() {
  local alg="${1:-md5}"
  local file="${2:-}"
  if [[ "$(Get_OS_Platform)" == MacOS ]]; then
    local cmd1; local cmd2;
    [[ "$alg" == sha512 ]] && cmd1="shasum -a 512 -b \"$file\"" && cmd2="openssl dgst -sha512 -r \"$file\""
    [[ "$alg" == sha384 ]] && cmd1="shasum -a 384 -b \"$file\"" && cmd2="openssl dgst -sha384 -r \"$file\""
    [[ "$alg" == sha256 ]] && cmd1="shasum -a 256 -b \"$file\"" && cmd2="openssl dgst -sha256 -r \"$file\""
    [[ "$alg" == sha224 ]] && cmd1="shasum -a 224 -b \"$file\"" && cmd2="openssl dgst -sha224 -r \"$file\""
    [[ "$alg" == sha1 ]] && cmd1="shasum -a 1 -b \"$file\"" && cmd2="openssl dgst -sha1 -r \"$file\""
    [[ "$alg" == md5 ]] && cmd1="md5 -r \"$file\"" && cmd2="openssl dgst -md5 -r \"$file\""
    local ret=""
    for cmd in "$cmd1" "$cmd2"; do
      if [[ -n "$cmd" ]]; then
        ret="$(eval $cmd 2>/dev/null | awk '{print $1}')"
        if [[ -n "$ret" ]]; then echo "$ret"; return; fi
      fi
    done
    # no sha sum
  else
    echo "$("${alg}sum" "$file" 2>/dev/null | awk '{print $1}')"
  fi
}

# Include File: [\Includes\Format_Size.sh]
function Format_Size() {
  local num="$1"
  local fractionalDigits="${2:-1}"
  local measureUnit="${3:-}"
  # echo "[DEBUG] Format_Size ARGS: num=$num measureUnit=$measureUnit fractionalDigits=$fractionalDigits" >&2
  awk -v n="$num" -v measureUnit="$measureUnit" -v fractionalDigits="$fractionalDigits" 'BEGIN { 
    if (n<1999) {
      y=n; s="";
    } else if (n<1999999) {
      y=n/1024.0; s="K";
    } else if (n<1999999999) {
      y=n/1024.0/1024.0; s="M";
    } else if (n<1999999999999) {
      y=n/1024.0/1024.0/1024.0; s="G";
    } else {
      y=n/1024.0/1024.0/1024.0/1024.0; s="T";
    }
    format="%." fractionalDigits "f";
    yFormatted=sprintf(format, y);
    if (length(s)==0) { yFormatted=y; }
    print yFormatted s measureUnit;
  }' 2>/dev/null || echo "$num"
}

# Include File: [\Includes\Format_Thousand.sh]
function Format_Thousand() {
  local num="$1"
  # LC_NUMERIC=en_US.UTF-8 printf "%'.0f\n" "$num" # but it is locale dependent
  # Next is locale independent version for positive integers
  awk -v n="$num" 'BEGIN { len=length(n); res=""; for (i=0;i<=len;i++) { res=substr(n,len-i+1,1) res; if (i > 0 && i < len && i % 3 == 0) { res = "," res } }; print res }' 2>/dev/null || echo "$num"
}

# Include File: [\Includes\get_glibc_version.sh]
# returns 21900 for debian 8
function get_glibc_version() {
  GLIBC_VERSION=""
  GLIBC_VERSION_STRING="$(ldd --version 2>/dev/null| awk 'NR==1 {print $NF}')"
  # '{a=$1; gsub("[^0-9]", "", a); b=$2; gsub("[^0-9]", "", b); if ((a ~ /^[0-9]+$/) && (b ~ /^[0-9]+$/)) {print a*10000 + b*100}}'
  local toNumber='{if ($1 ~ /^[0-9]+$/ && $2 ~ /^[0-9]+$/) { print $1 * 10000 + $2 * 100 }}'
  GLIBC_VERSION="$(echo "${GLIBC_VERSION_STRING:-}" | awk -F'.' "$toNumber")"

  if [[ -z "${GLIBC_VERSION:-}" ]] && [[ -n "$(command -v gcc)" ]]; then
    local cfile="$HOME/temp_show_glibc_version"
    rm -f "$cfile"
    cat <<-'EOF_SHOW_GLIBC_VERSION' > "$cfile.c"
#include <gnu/libc-version.h>
#include <stdio.h>
int main() { printf("%s\n", gnu_get_libc_version()); }
EOF_SHOW_GLIBC_VERSION
    GLIBC_VERSION_STRING="$(gcc $cfile.c -o $cfile 2>/dev/null && $cfile)"
    rm -f "$cfile"; rm -f "$cfile.c" 
    GLIBC_VERSION="$(echo "${GLIBC_VERSION_STRING:-}" | awk -F'.' "$toNumber")"
  fi
  echo "${GLIBC_VERSION:-}"
}

# Include File: [\Includes\Get_Global_Seconds.sh]
function Get_Global_Seconds() {
  theSYSTEM="${theSYSTEM:-$(uname -s)}"
  if [[ ${theSYSTEM} != "Darwin" ]]; then
      # uptime=$(</proc/uptime);                                # 42645.93 240538.58
      uptime="$(cat /proc/uptime 2>/dev/null)";                 # 42645.93 240538.58
      if [[ -z "${uptime:-}" ]]; then
        # secured, use number of seconds since 1970
        echo "$(date +%s)"
        return
      fi
      IFS=' ' read -ra uptime <<< "$uptime";                    # 42645.93 240538.58
      uptime="${uptime[0]}";                                    # 42645.93
      uptime=$(LC_ALL=C LC_NUMERIC=C printf "%.0f\n" "$uptime") # 42645
      echo $uptime
  else 
      # https://stackoverflow.com/questions/15329443/proc-uptime-in-mac-os-x
      boottime=`sysctl -n kern.boottime | awk '{print $4}' | sed 's/,//g'`
      unixtime=`date +%s`
      timeAgo=$(($unixtime - $boottime))
      echo $timeAgo
  fi
}

# Include File: [\Includes\Get_NET_RID.sh]
function Get_NET_RID() {
  local machine="$(uname -m)"; machine="${machine:-unknown}"
  local rid=unknown
  if [[ "$(Get_OS_Platform)" == Linux ]]; then
     local linux_arm linux_arm64 linux_x64
     if Test_Is_Musl_Linux; then
         linux_arm="linux-musl-arm"; linux_arm64="linux-musl-arm64"; linux_x64="linux-musl-x64"; 
     else
         linux_arm="linux-arm"; linux_arm64="linux-arm64"; linux_x64="linux-x64"
     fi
     if [[ "$machine" == armv7* ]]; then
       rid=$linux_arm;
     elif [[ "$machine" == aarch64 || "$machine" == armv8* || "$machine" == arm64* ]]; then
       rid=$linux_arm64;
       if [[ "$(Get_Linux_OS_Bits)" == "32" ]]; then 
         rid=$linux_arm; 
       fi
     elif [[ "$machine" == x86_64 ]] || [[ "$machine" == amd64 ]] || [[ "$machine" == i?86 ]]; then
       rid=$linux_x64;
       if [[ "$(Get_Linux_OS_Bits)" == "32" ]]; then 
         rid=linux-i386;
         echo "Warning! Linux 32-bit i386 is not supported by .NET Core" >&2
       fi
     fi;
     if [ -e /etc/redhat-release ]; then
       redhatRelease=$(</etc/redhat-release)
       if [[ $redhatRelease == "CentOS release 6."* || $redhatRelease == "Red Hat Enterprise Linux Server release 6."* ]]; then
         rid=rhel.6-x64;
         # echo "Warning! Support for Red Hat 6 in .NET Core ended at the end of 2021" >&2
       fi
     fi
  fi
  if [[ "$(Get_OS_Platform)" == MacOS ]]; then
       rid=osx-unknown;
       local osx_machine="$(sysctl -n hw.machine 2>/dev/null)"
       if [[ -z "$osx_machine" ]]; then osx_machine="$machine"; fi
       [[ "$osx_machine" == x86_64 ]] && rid="osx-x64"
       [[ "$osx_machine" == arm64 ]] && rid="osx-arm64"
       [[ "$osx_machine" == i?86 ]] && rid="osx-i386" && echo "Warning! OSX 32-bit i386 is not supported by .NET Core" >&2
       local osx_version="$(SYSTEM_VERSION_COMPAT=0 sw_vers -productVersion)"
       [[ "$osx_version" == 10.10.* ]] && rid="osx.10.10-x64"
       [[ "$osx_version" == 10.11.* ]] && rid="osx.10.11-x64"
  fi
  if [[ "$(Get_OS_Platform)" == Windows ]]; then
       rid="win-unknown"
       local win_arch="$(Get_Windows_OS_Architecture)"
       [[ "$win_arch" == x64 ]] && rid="win-x64"
       [[ "$win_arch" == arm ]] && rid="win-arm"
       [[ "$win_arch" == arm64 ]] && rid="win-arm64"
       [[ "$win_arch" == x86 ]] && rid="win"
       # workaround if powershell.exe is missing
       [[ "$win_arch" == i?86 ]] && rid="win" 
       [[ "$win_arch" == x86_64 ]] && rid="win-x64" 
       [[ "$win_arch" == arm64* || "$win_arch" == aarch64* ]] && rid="win-arm64"
  fi
  echo "$rid"
}

# return 32|64|<empty string>
Get_Linux_OS_Bits() {
  # getconf may be absent
  echo "$(getconf LONG_BIT 2>/dev/null)"
}

# x86|x64|arm|arm64
function Get_Windows_OS_Architecture() {
if [[ -z "$(command -v powershell)" ]]; then
  echo "$(uname -m)"
  return;
fi
local win_arch=$(cat <<'EOFWINARCH' | powershell -c -
function Has-Cmd {
  param([string] $arg)
  if ("$arg" -eq "") { return $false; }
  [bool] (Get-Command "$arg" -ErrorAction SilentlyContinue)
}

function Select-WMI-Objects([string] $class) {
  if (Has-Cmd "Get-CIMInstance")     { $ret = Get-CIMInstance $class; } 
  elseif (Has-Cmd "Get-WmiObject")   { $ret = Get-WmiObject   $class; } 
  if (-not $ret) { [Console]::Error.WriteLine("Warning! Missing neither Get-CIMInstance nor Get-WmiObject"); }
  return $ret;
}

function Get-CPU-Architecture-Suffix-for-Windows-Implementation() {
    # on multiple sockets x64
    $proc = Select-WMI-Objects "Win32_Processor";
    $a = ($proc | Select -First 1).Architecture
    if ($a -eq 0)  { return "x86" };
    if ($a -eq 1)  { return "mips" };
    if ($a -eq 2)  { return "alpha" };
    if ($a -eq 3)  { return "powerpc" };
    if ($a -eq 5)  { return "arm" };
    if ($a -eq 6)  { return "ia64" };
    if ($a -eq 9)  { 
      # Is 32-bit system on 64-bit CPU?
      # OSArchitecture: "ARM 64-bit Processor", "32-bit", "64-bit"
      $os = Select-WMI-Objects "Win32_OperatingSystem";
      $osArchitecture = ($os | Select -First 1).OSArchitecture
      if ($osArchitecture -like "*32-bit*") { return "x86"; }
      return "x64" 
    };
    if ($a -eq 12) { return "arm64" };
    return "";
}

Get-CPU-Architecture-Suffix-for-Windows-Implementation
EOFWINARCH
)
echo "$win_arch"
}

# Include File: [\Includes\Get_OS_Platform.sh]
function Get_OS_Platform() {
  _LIB_TheSystem="${_LIB_TheSystem:-$(uname -s)}"
  local ret="Unknown"
  [[ "$_LIB_TheSystem" == "Linux" ]] && ret="Linux"
  [[ "$_LIB_TheSystem" == "Darwin" ]] && ret="MacOS"
  [[ "$_LIB_TheSystem" == "FreeBSD" ]] && ret="FreeBSD"
  [[ "$(uname -s)" == "MSYS"* || "$(uname -s)" == "MINGW"* ]] && ret=Windows
  echo "$ret"
}

# Include File: [\Includes\Is_Qemu_VM.sh]
function Is_Qemu_VM() {
  _LIB_Is_Qemu_VM_Cache="${_LIB_Is_Qemu_VM_Cache:-$(Is_Qemu_VM_Implementation)}"
  echo "$_LIB_Is_Qemu_VM_Cache"
}

function Is_Qemu_VM_Implementation() {
  # termux checkup is Not required
  # if [[ "$(Is_Termux)" == True ]]; then return; fi
  local sudo;
  if [[ -z "$(command -v sudo)" ]]; then sudo=""; else sudo="sudo"; fi
  local qemu_shadow="$($sudo grep -r QEMU /sys/devices 2>/dev/null || true)"
  # test -d /sys/firmware/qemu_fw_cfg && echo "Ampere on this Oracle Cloud"
  if [[ "$qemu_shadow" == *"QEMU"* ]]; then
    echo True
  else
    echo False
  fi
}

# Include File: [\Includes\Is_Termux.sh]
function Is_Termux() {
  if [[ -n "${TERMUX_VERSION:-}" ]] && [[ -n "${PREFIX:-}" ]] && [[ -d "${PREFIX}" ]]; then
    echo True
  else
    echo False
  fi
}

# Include File: [\Includes\Is_Windows.sh]
function Is_Windows() {
  if Test_Is_Windows; then echo "True"; else echo "False"; fi
}

function Test_Is_Windows() {
  if [[ "$(Get_OS_Platform)" == "Windows" ]]; then return 0; else return 1; fi
}

function Is_WSL() {
  if Test_Is_WSL; then echo "True"; else echo "False"; fi
}

function Test_Is_WSL() {
  _LIB_TheKernel="${_LIB_TheKernel:-$(uname -r)}"
  if [[ "$_LIB_TheKernel" == *"Microsoft" ]]; then return 0; else return 1; fi
}

function Test_Is_Linux() {
  if [[ "$(Get_OS_Platform)" == "Linux" ]]; then return 0; else return 1; fi
}

function Is_Linux() {
  if Test_Is_Linux; then echo "True"; else echo "False"; fi
}

function Test_Is_MacOS() {
  if [[ "$(Get_OS_Platform)" == "MacOS" ]]; then return 0; else return 1; fi
}

function Is_MacOS() {
  if Test_Is_MacOS; then echo "True"; else echo "False"; fi
}


# Include File: [\Includes\MkTemp-Smarty.sh]
function MkTemp-Folder-Smarty() {
  local template="${1:-tmp}";
  local optionalPrefix="${2:-}";

  local tmpdirCopy="${TMPDIR:-/tmp}";
  # trim last /
  mkdir -p "$tmpdirCopy" >/dev/null 2>&1 || true; pushd "$tmpdirCopy" >/dev/null; tmpdirCopy="$PWD"; popd >/dev/null;

  local defaultBase="${DEFAULT_TMP_DIR:-$tmpdirCopy}";
  local baseFolder="${defaultBase}";
  if [[ -n "$optionalPrefix" ]]; then baseFolder="$baseFolder/$optionalPrefix"; fi;
  mkdir -p "$baseFolder";
  System_Type="${System_Type:-$(uname -s)}";
  local ret;
  if [[ "${System_Type}" == "Darwin" ]]; then
    ret="$(mktemp -t "$template")";
    rm -f "$ret" >/dev/null 2>&1 || true;
    rnd="$RANDOM"; rnd="${rnd:0:1}";
    # rm -rf may fail
    ret="$baseFolder/$(basename "$ret")${rnd}"; 
    mkdir -p "$ret";
  else
    # ret="$(mktemp -d --tmpdir="$baseFolder" -t "${template}.XXXXXXXXX")";
    ret="$(mktemp -t "$template".XXXXXXXXX)";
    rm -f "$ret" >/dev/null 2>&1 || true;
    rnd="$RANDOM"; rnd="${rnd:0:1}";
    # rm -rf may fail
    ret="$baseFolder/$(basename "$ret")${rnd}"; 
    mkdir -p "$ret";
  fi
  echo $ret;
}; 
# MkTemp-Folder-Smarty session
# MkTemp-Folder-Smarty session azure-api
# sudo mkdir -p /usr/local/tmp3; sudo chown -R "$(whoami)" /usr/local/tmp3
# DEFAULT_TMP_DIR=/usr/local/tmp3 MkTemp-Folder-Smarty session azure-api


# template: without .XXXXXXXX suffix
# optionalFolder if omited then ${TMPDIR:-/tmp}
function MkTemp-File-Smarty() {
  local template="${1:-tmp}";
  local optionalFolder="${2:-}";

  local tmpdirCopy="${TMPDIR:-/tmp}";
  # trim last /
  mkdir -p "$tmpdirCopy" >/dev/null 2>&1 || true; pushd "$tmpdirCopy" >/dev/null; tmpdirCopy="$PWD"; popd >/dev/null;

  local folder;
  if [[ -z "$optionalFolder" ]]; then folder="$tmpdirCopy"; else if [[ "$optionalFolder" == "/"* ]]; then folder="$optionalFolder"; else folder="$tmpdirCopy/$optionalFolder"; fi; fi
  mkdir -p "$folder"
  System_Type="${System_Type:-$(uname -s)}";
  local ret;
  if [[ "${System_Type}" == "Darwin" ]]; then
    ret="$(mktemp -t "$template")";
    rm -f "$ret" >/dev/null 2>&1 || true;
    local rnd="$RANDOM"; rnd="${rnd:0:1}";
    # rm -rf may fail
    ret="$folder/$(basename "$ret")${rnd}"; 
    mkdir -p "$(dirname "$ret")"
    touch "$ret"
  else
    ret="$(mktemp --tmpdir="$folder" -t "${template}.XXXXXXXXX")";
  fi
  echo $ret;
}; 




# Include File: [\Includes\RetryOnFail.sh]
function EchoRedError() { 
  say Red "\n$*\n"; 
}

function RetryOnFail() { 
  "$@" && return; 
  EchoRedError "Retrying 2 of 3 for \"$*\""; 
  sleep 1; 
  "$@" && return; 
  EchoRedError "Retrying 3 of 3 for \"$*\""; 
  sleep 1; 
  "$@"
}

# Include File: [\Includes\say.sh]
# say Green|Yellow|Red Hello World without quotes
say() { 
   local NC='\033[0m' Color_White='\033[1;37m' Color_Black='\033[1;30m' \
         Color_Red='\033[1;31m' Color_Green='\033[1;32m' Color_Yellow='\033[1;33m' Color_Blue='\033[1;34m' Color_Magenta='\033[1;35m' Color_Cyan='\033[1;36m' \
         Color_LightRed='\033[0;31m' Color_LightGreen='\033[0;32m' Color_LightYellow='\033[0;33m' Color_LightBlue='\033[0;34m' Color_LightMagenta='\033[0;35m' Color_LightCyan='\033[0;36m' Color_LightWhite='\033[0;37m'
   # local var="Color_${1:-}"
   # local color=""; [[ -n ${!var+x} ]] && color="${!var}"
   local color="$(eval "printf '%s' \"\$Color_${1:-}\"")"
   shift || true
   printf "${color:-}$*${NC}\n";
}
# say ZZZ the-incorrect-color

# Include File: [\Includes\Test_Has_Command.sh]
Test_Has_Command() {
  if command -v "${1:-}" >/dev/null 2>&1; then return 0; else return 1; fi
}

# Include File: [\Includes\Test_Is_Musl_Linux.sh]
Test_Is_Musl_Linux() {
  if Test_Has_Command getconf && getconf GNU_LIBC_VERSION >/dev/null 2>&1; then
    return 1;
  elif ldd --version 2>&1 | grep -iq "glibc"; then
    return 1;
  elif ldd /bin/ls 2>&1 | grep -q "musl"; then
    return 0;
  fi
  return 1; # by default GNU
}

Is_Musl_Linux() {
  if Test_Is_Musl_Linux; then echo "True"; else echo "False"; fi
}
# Include File: [\Includes\To_Boolean.sh]
# return True|False
function To_Boolean() {
  local name="${1:-}"
  local value="${2:-}"
  value="$(To_Lower_Case "$value")"
  if [[ "$value" == true ]] || [[ "$value" == on ]] || [[ "$value" == "1" ]] || [[ "$value" == "enable"* ]]; then echo "True"; return; fi
  if [[ "$value" == "" ]] || [[ "$value" == false ]] || [[ "$value" == off ]] || [[ "$value" == "0" ]] || [[ "$value" == "disable"* ]]; then echo "False"; return; fi
  echo "Validation Error! Invalid $name parameter '$value'. Boolean parameter accept only True|False|On|Off|Enable(d)|Disable(d)|1|0" >&2
}

# for x in True False 0 1 Enable Disable "" Enabled Disabled; do echo "[$x] as boolean is [$(To_Boolean "Arg" "$x")]"; done

# Include File: [\Includes\To_Lower_Case.sh]
function To_Lower_Case() {
  local a="${1:-}"
  if [[ -n "$(command -v tr)" ]]; then
    echo "$a" | tr '[:upper:]' '[:lower:]'
  elif [[ -n "$(command -v awk)" ]]; then
    echo "$a" | awk '{print tolower($0)}'
  else
    echo "WARNING! Unable to convert string to lower case" >&2
  fi
}
# x="  Hello  World!  "; echo "[$x] in lower case is [$(To_Lower_Case "$x")]"

# Include Directive: [ ..\Azure-DevOps-Api.Includes\*.sh ]
# Include File: [\Azure-DevOps-Api.Includes\$DEFAULTS.sh]
set -eu; set -o pipefail
# https://dev.azure.com
# https://stackoverflow.com/questions/43291389/using-jq-to-assign-multiple-output-variables
AZURE_DEVOPS_API_BASE="${AZURE_DEVOPS_API_BASE:-https://dev.azure.com/devizer/azure-pipelines-agent-in-docker}"
AZURE_DEVOPS_ARTIFACT_NAME="${AZURE_DEVOPS_ARTIFACT_NAME:-BinTests}"
AZURE_DEVOPS_API_PAT="${AZURE_DEVOPS_API_PAT:-}"; # empty for public project, mandatory for private
# PIPELINE_NAME="" - optional of more then one pipeline produce same ARTIFACT_NAME

# Include File: [\Azure-DevOps-Api.Includes\Azure-DevOps-DownloadViaApi.sh]
function Azure-DevOps-DownloadViaApi() {
  local url="$1"
  local file="$2";
  local header1="";
  local header2="";
  if [[ -n "${AZURE_DEVOPS_API_PAT:-}" ]]; then 
    local B64_PAT=$(printf "%s"":$API_PAT" | base64)
    # wget
    header1='--header="Authorization: Basic '${B64_PAT}'"'
    # curl
    header2='--header "Authorization: Basic '${B64_PAT}'"'
  fi
  local progress1="";
  local progress2="";
  if [[ "${API_SHOW_PROGRESS:-}" != "True" ]]; then
    progress1="-q -nv"
    progress2="-s"
  fi
  eval try-and-retry curl $header2 $progress2 -kfSL -o '$file' '$url' || eval try-and-retry wget $header1 $progress1 --no-check-certificate -O '$file' '$url'
  # download_file "$url" "$file"
  echo "$file"
}

# Include File: [\Azure-DevOps-Api.Includes\Azure-DevOps-GetArtifacts.sh]
# Colums:
#    Artifact ID
#    Name
#    Size in bytes
#    Download URL
function Azure-DevOps-GetArtifacts() {
  local buildId="${1:-}"
  if [[ -z "$buildId" ]]; then say Red "Azure-DevOps-GetArtifacts(): Missing #1 buildId parameter" 2>/dev/null; return; fi

  local url="${AZURE_DEVOPS_API_BASE}/_apis/build/builds/${buildId}/artifacts?api-version=6.0"
  local file=$(Azure-DevOps-GetTempFileFullName artifacts-$buildId);
  local json=$(Azure-DevOps-DownloadViaApi "$url" "$file.json")
  local f='.value | map({"id":.id|tostring, "name":.name, "size":.resource?.properties?.artifactsize?, "url":.resource?.downloadUrl?}) | map([.id, .name, .size, .url] | join("|")) | join("\n")'
  jq -r "$f" "$file.json" > "$file.txt"
  echo "$file.txt"
}

# Include File: [\Azure-DevOps-Api.Includes\Azure-DevOps-GetBuilds.sh]
# Colums:
#    Build ID
#    Build Number (string)
#    Pipeline Name
#    Result
#    Status
# GET https://dev.azure.com/{organization}/{project}/_apis/build/builds?definitions={definitions}&queues={queues}&buildNumber={buildNumber}&minTime={minTime}&maxTime={maxTime}&requestedFor={requestedFor}&reasonFilter={reasonFilter}&statusFilter={statusFilter}&resultFilter={resultFilter}&tagFilters={tagFilters}&properties={properties}&$top={$top}&continuationToken={continuationToken}&maxBuildsPerDefinition={maxBuildsPerDefinition}&deletedFilter={deletedFilter}&queryOrder={queryOrder}&branchName={branchName}&buildIds={buildIds}&repositoryId={repositoryId}&repositoryType={repositoryType}&api-version=6.0
function Azure-DevOps-GetBuilds() {
  # resultFilter: canceled|failed|none|partiallySucceeded|succeeded
  #               optional, if omitted get all builds
  local resultFilter="${1:-}"
  local url="${AZURE_DEVOPS_API_BASE}/_apis/build/builds?api-version=6.0"
  if [[ -n "$resultFilter" ]]; then url="${url}&resultFilter=$resultFilter"; fi
  local file=$(Azure-DevOps-GetTempFileFullName builds);
  local json=$(Azure-DevOps-DownloadViaApi "$url" "$file.json")
  local f='.value | map({"id":.id|tostring, "buildNumber":.buildNumber, p:.definition?.name?, r:.result, s:.status}) | map([.id, .buildNumber, .p, .r, .s] | join("|")) | join("\n") '
  jq -r "$f" "$file.json" | sort -r -k1 -n -t"|" > "$file.txt"
  echo "$file.txt"
}

# Include File: [\Azure-DevOps-Api.Includes\Azure-DevOps-GetTempFileFullName.sh]
function Azure-DevOps-GetTempFileFullName() {
  local template="$1"

  Azure-DevOps-Lazy-CTOR
  local ret="$(MkTemp-File-Smarty "$template" "$AZURE_DEVOPS_IODIR")";
  rm -f "$ret" >/dev/null 2>&1|| true
  echo "$ret"
}

# Include File: [\Azure-DevOps-Api.Includes\Azure-DevOps-Lazy-CTOR.sh]
function Azure-DevOps-Lazy-CTOR() {
  if [[ -z "${AZURE_DEVOPS_IODIR:-}" ]]; then
    AZURE_DEVOPS_IODIR="$(MkTemp-Folder-Smarty session azure-devops-api)"
    # echo AZUREAPI_IODIR: $AZUREAPI_IODIR
  fi
};

