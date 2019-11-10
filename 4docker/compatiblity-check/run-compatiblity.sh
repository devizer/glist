docker rm -f tests
docker run --name tests ubuntu:trusty bash -c 'source /etc/os-release; echo Im $PRETTY_NAME'
docker cp dotnet-3.0.sh tests:/dotnet-3.0.sh
docker exec -t tests bash -c 'bash -c /dotnet-3.0.sh'




