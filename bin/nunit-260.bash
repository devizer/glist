mkdir -p $HOME/bin
echo "#/bin/bash" > $HOME/bin/nu-c
echo mono --desktop --runtime=v4.0 \$HOME/bin/nunit-260/nunit-console.exe -labels \"\$\@\" >> $HOME/bin/nu-c
chmod 755 $HOME/bin/nu-c

wget -O /tmp/nunit-260.7z --no-check-certificate 'https://github.com/devizer/glist/raw/master/bin/nunit-260.7z'
# curl -k -o nunit-260.7z https://www.dropbox.com/s/sfunn3ypho2nfo0/nunit-260.7z?dl=1
7za x -y -o$HOME/bin /tmp/nunit-260.7z
rm -f /tmp/nunit-260.7z

mono --aot $HOME/bin/nunit-260/nunit-console.exe

cat $HOME/bin/nu-c
$HOME/bin/nu-c | grep -E 'NUnit-Console|Version'

echo '

export PATH="$PATH:$HOME/bin"
' >> ~/.bashrc
