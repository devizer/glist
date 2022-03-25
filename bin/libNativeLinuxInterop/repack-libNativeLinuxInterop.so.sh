work=/tmp/linuxtaskstats
mkdir -p $work
rm -rf $work/*
cd $work
curl -fkSL -o linuxtaskstats.zip https://globalcdn.nuget.org/packages/universe.linuxtaskstats.0.42.180-pre-1635.nupkg
unzip -o -q linuxtaskstats.zip
cd runtimes
mv rhel.6-x64 linux-rhel.6-x64
rm -rf any
find . -maxdepth 1 -type d | while read dir; do
  pushd $dir
  mv -f native/*.so .
  rm -rf lib native
  gzip -9 -k *.so
  popd
done
