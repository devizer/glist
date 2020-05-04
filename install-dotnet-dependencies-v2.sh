#!/usr/bin/env bash
# Here is one line installer 
# url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies-v2.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash

set -e1

# Open SUSE 42/15, SLES 12/15?
if [[ -n "$(command -v zypper || true)" ]]; then
  sudo zypper install -y lttng-ust curl libopenssl1_0_0 krb5 libicu zlib
fi

# Alpine Linux?
if [[ -n "$(command -v apk || true)" ]]; then
  apk add --no-cache --update sudo bash icu-libs ca-certificates \
    krb5-libs libgcc libstdc++ libintl libssl1.1 libstdc++ lttng-ust tzdata userspace-rcu zlib
fi

# CentOS/Fedora?
if [[ -n "$(command -v dnf || true)" ]]; then
  sudo dnf install -y lttng-ust libcurl openssl-libs krb5-libs libicu zlib
  # .NET 2x needs openssl 1.0.*
  sudo dnf info compat-openssl10 >/dev/null 2>&1
  if [ $? -eq 0 ]; then 
    printf "\nInstalling openssl 1.0 compatiblity\n"
    sudo dnf install -y compat-openssl10
  fi
# REDHAT?
elif [[ -n "$(command -v yum || true)" ]]; then
  sudo yum install -y lttng-ust libcurl openssl-libs krb5-libs libicu zlib
  # .NET 2x needs openssl 1.0.*
  sudo yum info -y compat-openssl10 >/dev/null 2>&1
  if [ $? -eq 0 ]; then 
    printf "\nInstalling openssl 1.0 compatiblity\n"
    sudo yum install -y compat-openssl10
  fi
fi

# Debian 8-9. Ubuntu 14.04-19.04
if [[ -n "$(command -v apt-get || true)" ]]; then
  libicu=$(apt-cache search libicu | grep -E '^libicu[0-9]* ' | awk '{print $1}')
  # libssl=$(apt-cache search libssl | grep -E '^libssl1\.0\.[0-9]* ' | awk '{print $1}')
  # The curl package here is a hack that installs correct version of both libssl and libcurl
  sudo apt-get install -y liblttng-ust0 curl libkrb5-3 zlib1g $libicu
fi
