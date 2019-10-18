#!/usr/bin/env bash
# script=https://raw.githubusercontent.com/devizer/glist/master/install-dotnet-core-3-x64.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash -s $HOME/.local/dotnet3

url=https://download.visualstudio.microsoft.com/download/pr/886b4a4c-30af-454b-8bec-81c72b7b4e1f/d1a0c8de9abb36d8535363ede4a15de6/dotnet-sdk-3.0.100-linux-x64.tar.gz
install_dir="$1"
install_dir=${install_dir:-$HOME/bin/dotnet3}
echo dotnet core install dir: $install_dir
mkdir -p "$install_dir"
file=$install_dir/$(basename "$url")
curl -o $file $url
tar xzf $file -C $install_dir
rm -f $file
sudo ln -s -f "$install_dir/dotnet" "/usr/local/bin/dotnet"
export PATH="$install_dir:$PATH"
dotnet --info

cat << UPGRADE_EOF > upgrade-2-to-3
#!/usr/bin/env bash
find -name '*.csproj' | while read csproj; do
  echo Upgrading \${csproj} to net core 3.0
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
