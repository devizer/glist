url=https://raw.githubusercontent.com/devizer/glist/master/4docker/compatiblity-check/dotnet-3.0.sh
curl -L -o dotnet-3.0.sh $url

docker rm -f tests
# trusty
# docker run --privileged -d --name tests ubuntu:trusty sh -c "while true; do sleep 4242; done"

# ARM
docker run --rm --privileged multiarch/qemu-user-static:register --reset
MULTIARCH_IMAGE="multiarch/debian-debootstrap:armhf-buster"
docker run -d --name tests -t "${MULTIARCH_IMAGE}" bash -c 'sleep 424242'


docker exec -t tests bash -c 'source /etc/os-release; echo Im $PRETTY_NAME; apt update; apt-get install -y -qq git sudo jq tar bzip2 gzip curl lsb-release procps gnupg apt-transport-https dirmngr ca-certificates mc htop'
docker cp dotnet-3.0.sh tests:/dotnet-3.0.sh
docker exec -t tests bash -c 'bash -eu /dotnet-3.0.sh'
