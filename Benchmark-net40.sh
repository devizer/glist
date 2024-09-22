url=https://raw.githubusercontent.com/devizer/glist/master/Benchmark-net40.exe; curl -ksfSL -o /tmp/Benchmark-net40.exe "$url"; mono /tmp/Benchmark-net40.exe

sudo mkdir -p /usr/local/share
sudo cp -v /tmp/Benchmark-net40.exe /usr/local/share/Benchmark-net40.exe
echo '#!/usr/bin/env bash
mono /usr/local/share/Benchmark-net40.exe
' | sudo tee /usr/local/bin/Benchmark > /dev/null
sudo chmod +x /usr/local/bin/Benchmark
Benchmark
