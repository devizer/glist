#!/usr/bin/env bash
# script=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-core-3-x64.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash -s dotnet node pwsh

url=https://download.visualstudio.microsoft.com/download/pr/b81a2bd3-a8a4-4c7e-bd69-030f412ff7b4/3fc5f2c0481313daf2e18c348362ff3f/dotnet-sdk-3.0.100-rc1-014190-linux-x64.tar.gz
install_dir=$HOME/bin/dotnet3
mkdir -p "$install_dir"
file=$install_dir/$(basename "$url")
curl -o $file $url
tar xzf $file -C $install_dir
rm -f $file
export PATH="$install_dir:$PATH"
dotnet --info

cat << UPGRADE_EOF > upgrade-2-to-3
#!/usr/bin/env bash
find -name '*.csproj' | while read csproj; do
  if [ ! -f "\${csproj}.bak" ]; then cp -f "\${csproj}" "\${csproj}.bak"; fi
  sed -i -e 's/netcoreapp2.2/netcoreapp3.0/g' "\${csproj}"
  sed -i -e 's/netstandard2.0/netstandard2.1/g' "\${csproj}"
done
UPGRADE_EOF
chmod +x upgrade-2-to-3


echo '
export PATH="$install_dir:$PATH"
' >> ~/.bashrc

sudo cp upgrade-2-to-3 /usr/local/bin
