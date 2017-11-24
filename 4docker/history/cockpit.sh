# (docker rm -f cockpit); docker run -it --name cockpit -p 9090:9090 debian:jessie bash
echo 'deb http://deb.debian.org/debian jessie-backports-sloppy main' > /etc/apt/sources.list.d/backports.list
apt-get update
apt-get install cockpit -y && (nohup /usr/lib/cockpit/cockpit-ws --no-tls & )

# run


Failed to get D-Bus connection: Unknown error -1

# (docker rm -f netdata); docker run -it --name netdata -p 19999:19999 debian:jessie bash
apt-get update && apt-get install curl htop nano lsof iotop mc psmisc binutils sudo -y && ( bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh) --non-interactive)


# nano /opt/netdata/etc/netdata/apps_groups.conf
# nano /etc/netdata/apps_groups.conf
# servers: mysqld mongod rabbitmq-server postgres redis-server
# /opt/netdata/bin/netdata
# https://raw.githubusercontent.com/firehol/binary-packages/master/netdata-latest.gz.run

( bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh) --non-interactive)
mkdir -p /etc/netdata
echo '
mysqld: mysqld 
mongod: mongod
rabbitmq-server: rabbitmq-server 
postgres: postgres 
redis-server: redis-server
' > /etc/netdata/apps_groups.conf
cp /etc/netdata/apps_groups.conf /opt/netdata/etc/netdata/apps_groups.conf

killall netdata 
killall netdata 
/opt/netdata/bin/netdata
