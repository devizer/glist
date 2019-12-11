#!/usr/bin/env bash
# script=https://raw.githubusercontent.com/devizer/glist/master/install-disk-benchmark-from-source.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -sSL $script) | bash

function install_disk_benchmark_from_source() {
   mkdir -p ~/build/disk-benchmark-source
   pushd ~/build/disk-benchmark-source
     git clone https://github.com/devizer/KernelManagementLab
     cd KernelManagementLab/BenchmarkLab
     git pull
     dotnet build -c Release -o bin/temp -f netcoreapp2.2
     dotnet=$(command -v dotnet)
     cd bin/temp
     exe="$(pwd)/Universe.Benchmark.dll"
     echo '#!/usr/bin/env bash
        set -e
        export DOTNET_ROOT="'$(dirname $dotnet)'"
        '$dotnet' '$exe' "$@"
     ' | sudo tee /usr/local/bin/disk-benchmark
     sudo chmod +x /usr/local/bin/disk-benchmark
   popd
   disk-benchmark --help
}

install_disk_benchmark_from_source
