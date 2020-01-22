# apt-get install docker-ce=5:18.09.0~3-0~ubuntu-bionic docker-ce-cli=5:18.09.0~3-0~ubuntu-bionic
MULTIARCH_IMAGE="multiarch/debian-debootstrap:arm64-stretch"
MULTIARCH_IMAGE="multiarch/debian-debootstrap:i386-stretch"
MULTIARCH_IMAGE="multiarch/debian-debootstrap:ppc64el-buster"
DOTNET_VER="2.2"

url=https://raw.githubusercontent.com/devizer/glist/master/4docker/compatiblity-check/mono-tests.sh
curl -L -o /tmp/tests.sh $url

docker rm -f tests 2>/dev/null
docker run --rm --privileged multiarch/qemu-user-static:register --reset
docker run --privileged -d --name tests -t "${MULTIARCH_IMAGE}" bash -c 'sleep 424242'

echo 'WORKS?
3.0: multiarch/debian-debootstrap:armhf-buster
2.2: multiarch/debian-debootstrap:aarch64-buster
'

docker exec -t tests bash -c 'echo "uname -m: $(uname -m)"; free -m'
docker exec -t tests bash -c 'source /etc/os-release; echo I am $PRETTY_NAME; echo It is $(uname -m) CPU; apt-get update -qq; apt-get install -y -qq git sudo jq tar bzip2 gzip curl lsb-release procps gnupg2 apt-transport-https dirmngr ca-certificates mc htop nano sudo bash procps mc htop; free -m'
docker cp /tmp/tests.sh tests:/tests.sh
docker exec -t tests bash -c "export DOTNET_VER=$DOTNET_VER; bash -eu /tests.sh" || echo "FFFFFFFAAAAAAAAIIIIIIIIL"

docker cp tests:/app/bin/app /tmp/app
file /tmp/app
docker stop tests

