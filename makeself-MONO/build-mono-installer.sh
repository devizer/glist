#!/bin/bash

SRC=/opt/mono/4.4.2.11
sudo find $SRC -name "*.so" -o -name mono-sgen -exec strip {} \;
label="mono 4.4.2.11 armv6 (with libc6 aka glibc 2.19) at $SRC"
chmod 755 try-mono.sh
sudo cp try-mono.sh $SRC
export GZIP=-9
time (makeself.sh $SRC "mono-4.4.2.11(glibc-2.19).gz.sh" "$label" ./try-mono.sh $SRC)

