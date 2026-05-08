file=Benchmark.cs
url=https://raw.githubusercontent.com/devizer/glist/master/$file; curl -ksfSL -o /tmp/$file "$url";


folder=/opt/benchmark-net-core
dotnet new console -o $folder --force
sudo cp -v /tmp/$file $folder/Program.cs
pushd $folder
dotnet build -c Release -o bin -p:AllowUnsafeBlocks=true
popd

dotnet $folder/bin/benchmark-net-core.dll

sudo mkdir -p /usr/local/share
echo '#!/usr/bin/env bash
set -e; dotnet '$folder'/bin/benchmark-net-core.dll
' | sudo tee /usr/local/bin/Benchmark-Net-Core > /dev/null
sudo chmod +x /usr/local/bin/Benchmark-Net-Core
Benchmark-Net-Core
