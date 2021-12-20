#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/bin/fix-mono-runtimes.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash

function download_runtimes() {
  local pkg=$1
  name=$(basename $pkg)
  echo "Downloding $name"
  work=/tmp/_mono_runtimes_
  mkdir -p $work
  sudo rm -rf $work/*
  archive=$pkg
  file=$work/$name
  cmd="(wget -O $file --no-check-certificate $archive 2>/dev/null || curl -o $file -kSL $archive)"
  eval "$cmd" || eval "$cmd" || eval "$cmd" || rm -f $file
  echo "Extracting $name"
  unzip -o -q -d $work $file
  cp -r $work/runtimes .
  for ext in pdb dll xml; do
    find runtimes -name '*.'$ext -exec sh -c "echo deleting {}; rm {}" \;
  done
  rm -rf $work/*
}

if [[ -s Mono.Unix.dll ]]; then
echo '<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <dllmap dll="Mono.Unix" os="linux" cpu="x86-64" wordsize="64" target="runtimes/linux-x64/native/libMono.Unix.so" />
  <dllmap dll="Mono.Unix" os="linux" cpu="arm" wordsize="32" target="runtimes/linux-arm/native/libMono.Unix.so" />
  <dllmap dll="Mono.Unix" os="linux" cpu="armv8" wordsize="64" target="runtimes/linux-arm64/native/libMono.Unix.so" />
  <dllmap dll="Mono.Unix" os="osx" cpu="x86-64" wordsize="64" target="runtimes/osx-x64/native/libMono.Unix.dylib" />
  <dllmap dll="Mono.Unix" os="osx" cpu="armv8" wordsize="64" target="runtimes/osx-arm64/native/libMono.Unix.dylib" />
</configuration>' > Mono.Unix.dll.config
download_runtimes https://globalcdn.nuget.org/packages/mono.unix.7.1.0-final.1.21458.1.nupkg
fi

if [[ -s Universe.LinuxTaskStats.dll ]]; then
echo '<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <dllmap dll="libNativeLinuxInterop" os="linux" cpu="x86-64" wordsize="64" target="runtimes/linux-x64/native/libNativeLinuxInterop.so" />
  <dllmap dll="libNativeLinuxInterop" os="linux" cpu="arm" wordsize="32" target="runtimes/linux-arm/native/libNativeLinuxInterop.so" />
  <dllmap dll="libNativeLinuxInterop" os="linux" cpu="armv8" wordsize="64" target="runtimes/linux-arm64/native/libNativeLinuxInterop.so" />
</configuration>' > Universe.LinuxTaskStats.dll.config
download_runtimes https://globalcdn.nuget.org/packages/universe.linuxtaskstats.0.42.180-pre-1635.nupkg
fi
