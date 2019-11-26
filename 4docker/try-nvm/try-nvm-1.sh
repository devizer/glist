docker rm -f nvm
docker run -h nvm -d --name nvm -t debian:10 bash -c 'sleep 424242'
cmd='source /etc/os-release; 
echo Im $PRETTY_NAME; 
apt update; 
apt-get install -y -qq git sudo jq tar bzip2 gzip curl lsb-release procps gnupg apt-transport-https dirmngr ca-certificates mc htop nano
export NVM_DIR="/opt/nvm"
mkdir -p /opt/nvm
script=https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh; (wget -q -nv --no-check-certificate -O - $script 2>/dev/null || curl -ksSL $script) | bash
'

docker exec -t nvm bash -c "$cmd"
docker exec -it nvm bash
# 'source /etc/os-release; echo Im $PRETTY_NAME; apt update; apt-get install -y -qq git sudo jq tar bzip2 gzip curl lsb-release procps gnupg apt-transport-https dirmngr ca-certificates mc htop nano'
