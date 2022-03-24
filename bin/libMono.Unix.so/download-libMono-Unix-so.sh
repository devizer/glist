set -eu; set -o pipefail
machine=$(uname -m);
[[ $machine == x86_64 ]] && [[ "$(getconf LONG_BIT)" == "32" ]] && machine=i386
[[ $machine == aarch64 ]] && machine=arm64
[[ $machine == armv* ]] && machine=arm32v7
[[ "$(dpkg --print-architecture)" == armel ]] && machine=arm32v5

url="https://raw.githubusercontent.com/devizer/glist/master/bin/libMono.Unix.so/${machine}/libMono.Unix.so"
file=/tmp/libMono.Unix.so
echo "  url: $url
 file: $file"

curl -fkSL -o "$file" "$url" || curl -fkSL -o "$file" "$url" || curl -fkSL -o "$file" "$url"

dir="${1:$(pwd)}
echo "Searching Mono.Unix.dll in [$dir]"
n=0;
find "$dir" -name "Mono.Unix.dll" | while read file; do
  to="$(dirname "$file")"
  echo "Copying libMono.Unix.so to [$to]"
  cp -f "$file" "$to/libMono.Unix.so"
  n=$((n+1))
done
echo "Done. Total libMono.Unix.so deployed: [$n]"
