#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies-v2.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

set -e

# Open SUSE Leap 42/15 & tumbleweed. SLES 12/15?
if [[ -n "$(command -v zypper || true)" ]]; then
  # examples of libicu: opensuse/leap:15 - libicu60_2, opensuse:tumbleweed - libicu66
  libicu=$(zypper se libicu | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^libicu[_0-9]*$/) { print n} }')
  # For .net net 3x we need libopenssl1_1 instead of libopenssl1_0_0
  # For the old OpenSUSE 42 we need lttng-ust. For current - liblttng-ust0
  lttng_legacy=$(zypper se lttng-ust | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^lttng-ust$/) { print n} }')
  lttng_current=$(zypper se liblttng-ust0 | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^liblttng-ust0$/) { print n} }')
  libssl1_1=$(zypper se libopenssl1_1 | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^libopenssl1_1$/) { print n} }')
  sudo zypper install -y $lttng_legacy $lttng_current curl libopenssl1_0_0 $libssl1_1 krb5 "$libicu" zlib
fi

# Alpine Linux 3.7, 3.8
if [[ -n "$(command -v apk || true)" ]]; then
  # either libssl1.0 or libssl1.1 depending on Alpine version
  libssl=$(apk search libssl | awk -F'-' '{n=$1; gsub(/ /,"", n); if (n ~ /^libssl[\.0-9]*$/) { print n} }')
  apk add --no-cache --update sudo bash icu-libs ca-certificates \
    krb5-libs libgcc libstdc++ libintl $libssl libstdc++ lttng-ust tzdata userspace-rcu zlib
fi

# CentOS 6,7,8. Fedora 26 - 31
if [[ -n "$(command -v dnf || true)" ]]; then
  sudo dnf install -y --nogpg --nogpgcheck --allowerasing lttng-ust libcurl openssl-libs krb5-libs libicu zlib
  # .NET 2x needs openssl 1.0.*
  sudo dnf info compat-openssl10 >/dev/null 2>&1 && (
    printf "\nInstalling openssl 1.0 compatiblity\n"
    sudo dnf install -y compat-openssl10
  )
# REDHAT?
elif [[ -n "$(command -v yum || true)" ]]; then
  # probably --nogpg is also needed
  # for amazon linux v1 and v2 lttng-ust is missing
  sudo yum install -y lttng-ust libcurl openssl-libs krb5-libs libicu zlib
  # .NET 2x needs openssl 1.0.*
  sudo yum info -y compat-openssl10 >/dev/null 2>&1 && (
    printf "\nInstalling openssl 1.0 compatiblity\n"
    sudo yum install -y compat-openssl10
  )
fi

# Debian 8-11. Ubuntu 12.04-20.04 including non-LTS versions
if [[ -n "$(command -v apt-get || true)" ]]; then
  libicu=$(apt-cache search libicu | grep -E '^libicu[0-9]* ' | awk '{print $1}')
  # libssl=$(apt-cache search libssl | grep -E '^libssl1\.0\.[0-9]* ' | awk '{print $1}')
  # The curl package here is a hack that installs correct version of both libssl and libcurl
  sudo apt-get install -y liblttng-ust0 curl libkrb5-3 zlib1g $libicu
fi
