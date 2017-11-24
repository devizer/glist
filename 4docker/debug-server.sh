docker exec -it server bash -c "command -v nano || (apt-get install -y mc nano less lsof htop psmisc binutils sudo); export TERM=xterm; bash"

