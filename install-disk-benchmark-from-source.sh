#!/usr/bin/env bash
# script=https://raw.githubusercontent.com/devizer/glist/master/install-disk-benchmark-from-source.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -sSL $script) | bash

function install_disk_benchmark_from_source() {

   if [[ "$(command -v dotnet)" == "" ]]; then
      export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
      export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
      export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
      export DOTNET_CLI_TELEMETRY_OPTOUT=1
      url=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-dependencies.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -ksSL $url) | bash
      DOTNET_Url=https://dot.net/v1/dotnet-install.sh; 
      mkdir -p ~/tmp/dotnet ~/.dotnet/tools
      export PATH="$PATH:$HOME/.dotnet/tools:$HOME/tmp/dotnet"
      export DOTNET_ROOT="$HOME/tmp/dotnet"
      curl -o /tmp/_dotnet-install.sh -ksSL $DOTNET_Url
      
      echo "Installing .NET Core 2.2 SDK"
      bash /tmp/_dotnet-install.sh -c 2.2 -i ~/tmp/dotnet
   fi

   [[ "$(uname -s)" == "MSYS"* || "$(uname -s)" == "MINGW"* ]] && OS=Windows
   echo "OS: $OS"
   
   mkdir -p ~/build/disk-benchmark-source
   pushd ~/build/disk-benchmark-source >/dev/null
     git clone https://github.com/devizer/KernelManagementLab "$(pwd)/KernelManagementLab"
     cd KernelManagementLab/BenchmarkLab
     git pull
     dotnet build -c Release -o bin/temp -f netcoreapp2.2 -v q
     dotnet=$(command -v dotnet)
     cd bin/temp
     exe="$(pwd)/Universe.Benchmark.dll"
     if [[ -f "$exe" ]]; then
        if [[ "${OS}" == Windows ]]; then
            echo "Creating C:\\Windows\\disk-benchmark.cmd for '$dotnet $exe'"
            echo '@dotnet "'$exe'" %*' > C:\\Windows\\disk-benchmark.cmd
            ls -la C:\\Windows\\disk-benchmark.cmd
            cat C:\\Windows\\disk-benchmark.cmd
        else
            echo "Creating /usr/local/bin/disk-benchmark for '$dotnet $exe'"
            echo '#!/usr/bin/env bash
               set -e
               export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
               export DOTNET_ROOT="'$(dirname $dotnet)'"
               '$dotnet' '$exe' "$@"
            ' | sudo tee /usr/local/bin/disk-benchmark
            sudo chmod +x /usr/local/bin/disk-benchmark
        fi
     fi
   popd >/dev/null
   disk-benchmark --help
   disk-benchmark.cmd --help
}

install_disk_benchmark_from_source
