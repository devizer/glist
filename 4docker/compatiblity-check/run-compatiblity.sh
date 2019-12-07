# apt-get install docker-ce=5:18.09.0~3-0~ubuntu-bionic docker-ce-cli=5:18.09.0~3-0~ubuntu-bionic
MULTIARCH_IMAGE="multiarch/debian-debootstrap:arm64-stretch"
MULTIARCH_IMAGE="multiarch/debian-debootstrap:i386-stretch"
DOTNET_VER="2.2"

url=https://raw.githubusercontent.com/devizer/glist/master/4docker/compatiblity-check/dotnet-and-tests.sh
curl -L -o /tmp/dotnet-and-tests.sh $url

docker rm -f tests 2>/dev/null
docker run --rm --privileged multiarch/qemu-user-static:register --reset
docker run -d --name tests -t "${MULTIARCH_IMAGE}" bash -c 'sleep 424242'

echo 'WORKS?
3.0: multiarch/debian-debootstrap:armhf-buster
2.2: multiarch/debian-debootstrap:aarch64-buster
'

docker exec -t tests bash -c 'echo "uname -m: $(uname -m)"'
docker exec -t tests bash -c 'source /etc/os-release; echo Im $PRETTY_NAME; apt update; apt-get install -y -qq git sudo jq tar bzip2 gzip curl lsb-release procps gnupg apt-transport-https dirmngr ca-certificates mc htop nano'
docker cp /tmp/dotnet-and-tests.sh tests:/dotnet-and-tests.sh
docker exec -t tests bash -c "export DOTNET_VER=$DOTNET_VER; bash -eu /dotnet-and-tests.sh" || echo "FFFFFFFAAAAAAAAIIIIIIIIL"

docker cp tests:/app/bin/app /tmp/app
file /tmp/app
docker stop tests

