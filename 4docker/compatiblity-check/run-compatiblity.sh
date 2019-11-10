url=https://raw.githubusercontent.com/devizer/glist/master/4docker/compatiblity-check/dotnet-3.0.sh
curl -L -o dotnet-3.0.sh $url

docker rm -f tests
docker run --privileged -d --name tests ubuntu:trusty sh -c "while true; do sleep 4242; done"

docker exec -t tests bash -c 'source /etc/os-release; echo Im $PRETTY_NAME'
docker cp dotnet-3.0.sh tests:/dotnet-3.0.sh
docker exec -t tests bash -c 'bash -eu /dotnet-3.0.sh'





