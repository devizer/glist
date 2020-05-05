#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies-v2.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

set -e

# Open SUSE 42/15, SLES 12/15?
if [[ -n "$(command -v zypper || true)" ]]; then
  # examples of libicu: opensuse/leap:15 - libicu60_2, opensuse:tumbleweed - libicu66
  libicu=$(zypper se libicu | awk -F'|' '{n=$2; gsub(/ /,"", n); if (n ~ /^libicu[_0-9]*$/) { print n} }')
  # for .net net 3x we need libopenssl1_1 instead of libopenssl1_0_0
  sudo zypper install -y liblttng-ust0 curl libopenssl1_0_0 krb5 "$libicu" zlib
fi

# Alpine Linux?
if [[ -n "$(command -v apk || true)" ]]; then
  # either libssl1.0 or libssl1.1 depending on Alpine version
  libssl=$(apk search libssl | awk -F'-' '{n=$1; gsub(/ /,"", n); if (n ~ /^libssl[\.0-9]*$/) { print n} }')
  apk add --no-cache --update sudo bash icu-libs ca-certificates \
    krb5-libs libgcc libstdc++ libintl $libssl libstdc++ lttng-ust tzdata userspace-rcu zlib
fi

# CentOS/Fedora?
if [[ -n "$(command -v dnf || true)" ]]; then
  sudo dnf install -y lttng-ust libcurl openssl-libs krb5-libs libicu zlib
  # .NET 2x needs openssl 1.0.*
  sudo dnf info compat-openssl10 >/dev/null 2>&1 && (
    printf "\nInstalling openssl 1.0 compatiblity\n"
    sudo dnf install -y compat-openssl10
  )
# REDHAT?
elif [[ -n "$(command -v yum || true)" ]]; then
  sudo yum install -y lttng-ust libcurl openssl-libs krb5-libs libicu zlib
  # .NET 2x needs openssl 1.0.*
  sudo yum info -y compat-openssl10 >/dev/null 2>&1 && (
    printf "\nInstalling openssl 1.0 compatiblity\n"
    sudo yum install -y compat-openssl10
  )
fi

# Debian 8-11. Ubuntu 14.04-20.04
if [[ -n "$(command -v apt-get || true)" ]]; then
  libicu=$(apt-cache search libicu | grep -E '^libicu[0-9]* ' | awk '{print $1}')
  # libssl=$(apt-cache search libssl | grep -E '^libssl1\.0\.[0-9]* ' | awk '{print $1}')
  # The curl package here is a hack that installs correct version of both libssl and libcurl
  sudo apt-get install -y liblttng-ust0 curl libkrb5-3 zlib1g $libicu
fi
