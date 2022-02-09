#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | UPDATE_REPOS=true bash -e && echo "Successfully installed .NET Core Dependencies"

function smart_sudo() {
  if [[ -n "$(command -v sudo || true)" ]]; then
    eval "sudo $1"
  else
    # docker containers ususally does not have preinstalled sudo because it is good enough without sudo.
    eval "$1"
  fi
}

UPDATE_REPOS="${UPDATE_REPOS:-false}"

# Autotests: Open SUSE Leap 42/15 & Tumbleweed. 
# Manual Tests: SLES 12 SP5, SLES 15 SP1
# After creating SLES 12/15 image in a cloud, it needs to wait for a few minutes for background repos maintenance tasks
if [[ -n "$(command -v zypper || true)" ]]; then
  if [[ "$UPDATE_REPOS" == "true" ]]; then smart_sudo "zypper refresh || true"; fi
  # examples of libicu: opensuse/leap:15 - libicu60_2, opensuse:tumbleweed - libicu66
  libicu=$(zypper se libicu | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^libicu[_0-9]*$/) { print n} }')
  # For .net net 3x we need libopenssl1_1 instead of libopenssl1_0_0
  # For the old OpenSUSE 42 we need lttng-ust. For current - liblttng-ust0
  lttng_legacy=$(zypper se lttng-ust | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^lttng-ust$/) { print n} }')
  lttng_current=$(zypper se liblttng-ust0 | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^liblttng-ust0$/) { print n} }')
  libssl1_1=$(zypper se libopenssl1_1 | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^libopenssl1_1$/) { print n} }')
  libssl1_0_0=$(zypper se libopenssl1_0_0 | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^libopenssl1_0_0$/) { print n} }')
  smart_sudo "zypper install -y $lttng_legacy $lttng_current curl $libssl1_0_0 $libssl1_1 krb5 $libicu zlib"
fi

# Alpine Linux 3.7, 3.8
if [[ -n "$(command -v apk || true)" ]]; then
  # either libssl1.0 or libssl1.1 depending on Alpine version
  libssl=$(apk search libssl | awk -F'-' '{n=$1; gsub(/ /,"", n); if (n ~ /^libssl[\.0-9]*$/) { print n} }')
  smart_sudo "apk add --no-cache --update sudo bash icu-libs ca-certificates krb5-libs libgcc libstdc++ libintl $libssl libstdc++ lttng-ust tzdata userspace-rcu zlib"
fi

# CentOS 8. Fedora 26 - 31, 
# Manual Tests: Red Hat 8.2
if [[ -n "$(command -v dnf || true)" ]]; then
  smart_sudo "yum install -y -q --nogpg --nogpgcheck --allowerasing lttng-ust libcurl openssl-libs krb5-libs libicu zlib"
  # .NET 2x needs openssl 1.0.*
  dnf info compat-openssl10 -y >/dev/null 2>&1 && (
    printf "\nInstalling openssl 1.0 compatiblity\n"
    smart_sudo "dnf install -y -q --nogpg --nogpgcheck compat-openssl10"
  )
# Tested: CentOS/RHEL 6, 7
elif [[ -n "$(command -v yum || true)" ]]; then
  # for Amazon Linux v1 and v2 lttng-ust is missing, but yum does not fail.
  # missing --allowerasing on CentOS 7
  # openssl11 is for RHEL 7 only, for CentOS 7 & RHEL 6 it is missing
  openssl11=$(yum search openssl11 -y 2>/dev/null | awk -F'.' '{n=$1; gsub(/ /,"", n); if (n ~ /^openssl11$/) { print n} }')
  smart_sudo "yum install -y -q --nogpg --nogpgcheck lttng-ust libcurl $openssl11 openssl-libs krb5-libs libicu zlib"
  # .NET 2x needs openssl 1.0.*
  yum info -y compat-openssl10 -y >/dev/null 2>&1 && (
    printf "\nInstalling openssl 1.0 compatiblity\n"
    smart_sudo "yum install -y -q --nogpg --nogpgcheck compat-openssl10"
  )
fi

# Debian 8-11. Ubuntu 12.04-20.04 including non-LTS versions
if [[ -n "$(command -v apt-get || true)" ]]; then
  if [[ "$UPDATE_REPOS" == "true" ]]; then smart_sudo "apt-get update --allow-unauthenticated -y -q"; fi
  liblttng="$(apt-cache search liblttng-ust0 | awk '{print $1}' | grep 'liblttng-ust0')"
  libicu="$(apt-cache search libicu | grep -E '^libicu[0-9]* ' | awk '{print $1}')"
  libunwind="$(apt-cache search libunwind | grep -E '^libunwind[0-9]* ' | awk '{print $1}')"
  libuuid="$(apt-cache search libuuid | grep -E '^libuuid[0-9]* ' | awk '{print $1}')"
  # libssl1.1 libssl1.0.0
  libssl11="$(apt-cache search libssl1.1 | grep -E '^libssl1\.1 ' | awk '{print $1}')"
  libssl10="$(apt-cache search libssl1.0.0 | grep -E '^libssl1\.0\.0 ' | awk '{print $1}')"
  packages="curl libkrb5-3 zlib1g $libicu $libssl10 $libssl11 $libunwind $libuuid $liblttng"
  # Replace newlines by spaces
  packages="$(echo "$packages" | sed ':a;N;$!ba;s/\n/ /g')"
  # Replace double-spaces by spaces
  packages="$(echo "$packages" | sed ':a;N;$!ba;s/  / /g')"
  echo "Installing .net core dependencies: $packages"
  # libssl=$(apt-cache search libssl | grep -E '^libssl1\.0\.[0-9]* ' | awk '{print $1}')
  # The curl package here is a hack that installs correct version of both libssl and libcurl
  smart_sudo "apt-get install -y -q --allow-unauthenticated $packages"
fi
