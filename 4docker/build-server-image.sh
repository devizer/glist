#!/bin/bash

cat << _Dockerfile_ > Dockerfile
# help: https://cloud.google.com/appengine/docs/flexible/dotnet/customizing-the-dotnet-runtime
FROM debian:jessie
COPY . /prerequisites
WORKDIR /prerequisites
SHELL ["bash", "-c"]

#      MySQL  APPS       PostgreSQL   RabbitMQ    MongoDB  NetData  SSH  REDIS
EXPOSE 3306   5001-5009  5432         5672 15672  27017    19999    22   6379

ENV ASPNETCORE_URLS=http://+:5001

# RUN (echo -e '#!/bin/bash\nexit 0' > /usr/sbin/policy-rc.d)

# pre-intall regular tools
RUN apt-get update && apt-get install wget curl xz-utils p7zip-full sudo procps binutils figlet -y && apt-get clean 


# pre-install MySQL Server 5.5 with root's password=root.
# network access: --user=mysql --password=mysql
# mysql --user=root --password=root --host=127.0.0.1 --port=3306 -e 'Show Variables Like "%VERSION%";'
RUN printf '\n\n\n'; figlet -t -- ' MySQL  *  5.5' \
  && (echo mysql-server-5.5 mysql-server/root_password password root | debconf-set-selections) \
  && (echo mysql-server-5.5 mysql-server/root_password_again password root | debconf-set-selections) \
  && (apt-get -y install mysql-server-5.5 && service mysql start) \
  && (cat .my.cnf >> /etc/mysql/my.cnf) && service mysql restart \
  && echo MySQL VERSION && mysql --user=root --password=root -e 'Show Variables Like "%VERSION%";' -t \
  && mysql --user=root --password=root -e "CREATE USER 'mysql'@'%' IDENTIFIED BY 'mysql'; GRANT ALL PRIVILEGES ON *.* TO 'mysql'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;" \
  && mysql --user=root --password=root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES;" \
  && service mysql stop && apt-get clean


RUN printf '\n\n\n'; figlet -t -- '.Net  *  SDK' \
 && export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
 && export DOTNET_CLI_TELEMETRY_OPTOUT=1 \
 && apt-get update && apt-get -y install curl libunwind8 gettext apt-transport-https \
 && curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
 && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
 && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-jessie-prod jessie main" > /etc/apt/sources.list.d/dotnetdev.list' \
 && apt-get update && apt-get install -y dotnet-sdk-2.0.3 && apt-get clean \
 && dotnet new mvc -o dummy && rm -rf dummy


RUN printf '\n\n\n'; figlet -t -- ' ==*  SSH  *==' \
  && passwd -u root && echo 'root:sandbox'|chpasswd \
  && apt-get install -y openssh-server \
  && (cat /etc/ssh/sshd_config | grep -v PermitRootLogin | grep -v PasswordAuthentication > .sshd_config) \
  && (echo -e "\n\nPasswordAuthentication yes\nPermitRootLogin yes" >> .sshd_config) \
  && cp .sshd_config /etc/ssh/sshd_config \
  && service ssh start 


RUN # printf '\n\n\n'; figlet -t -- ' ==*  REDIS  2.8  *==' \
  && apt-get -y install redis-server \
  && (sed -i.bak '/bind/d' /etc/redis/redis.conf || true) \
  && (echo -e "\nbind *\nmaxmemory 100M" >> /etc/redis/redis.conf) \
  && service redis-server restart \
  && echo REDIS \$(echo info | redis-cli | grep redis_version) \
  && service redis-server stop && apt-get clean


RUN printf '\n\n\n'; figlet -t -- ' REDIS  *  3.2' \
  && (echo 'deb http://packages.dotdeb.org jessie all' > /etc/apt/sources.list.d/dotdeb.list) \
  && wget --no-check-certificate -O dotdeb.gpg https://www.dotdeb.org/dotdeb.gpg \
  && apt-key add dotdeb.gpg \
  && apt-get update && apt-get install -y redis-server \
  && (sed -i.bak '/bind/d' /etc/redis/redis.conf || true) \
  && (echo -e "\nbind *\nmaxmemory 100M" >> /etc/redis/redis.conf) \
  && service redis-server restart \
  && (ps ax -o pid,pcpu,rss,vsz,args | grep redis-server | grep -v grep) || true \
  && echo REDIS \$(echo info | redis-cli | grep redis_version) \
  && service redis-server stop && apt-get clean



RUN printf '\n\n\n'; figlet -t -- ' *  NETDATA  *' \
  && mkdir -p /etc/netdata && mkdir -p /opt/netdata/etc/netdata \
  && (echo -e 'mysqld: mysqld \nmongod: mongod \n rabbitmq-server: rabbitmq-server \n postgres: postgres \n redis-server: redis-server' > /etc/netdata/apps_groups.conf) \
  && cp /etc/netdata/apps_groups.conf /opt/netdata/etc/netdata/apps_groups.conf \
  && ( bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh) --non-interactive) 


# pre-install mongodb-server 3.4
RUN printf '\n\n\n'; figlet -t -- ' Mongo  *  3.4' \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 \
  && echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" > /etc/apt/sources.list.d/mongodb-org-3.4.list \
  && apt-get update && apt-get install -y mongodb-org-server \
  && cp mongodb-server /etc/init.d/mongodb-server && update-rc.d mongodb-server defaults \
  && apt-get clean


# pre-intall: FFMPEG latest
RUN printf '\n\n\n'; figlet -t -- ' *  FFMPEG  *' \
  && wget --no-check-certificate -O ffmpeg-release-64bit-static.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-64bit-static.tar.xz \
  && time (tar -xJf ffmpeg-release-64bit-static.tar.xz) \
  && cd ffmpeg* \
  && d=\$(pwd) \
  && cp ff* /usr/bin \
  && cd .. && rm -rf "\$d" && rm -f ffmpeg-release-64bit-static.tar.xz \
  && echo -e "\n\nFFPROBE VERSION" && ffprobe -version




# Peer authentication failed for user "postgre"?
RUN printf '\n\n\n'; figlet -t -- ' PostgreSQL  *  9.4' \
  && (apt-get -y install postgresql) \
  && (echo -e "\nlisten_addresses = '*' " >> /etc/postgresql/9.4/main/postgresql.conf) \
  && (echo -e "\n\nlocal all all  trust\nhost all all 255.255.255.255/0 trust" > /etc/postgresql/9.4/main/pg_hba.conf) \
  && service postgresql restart \
  && echo -e "\n\nPOSTGRESQL VERSION: " && psql postgres postgres -c 'SELECT Version();' \
  && service postgresql stop && apt-get clean


# pre-install RabbitMQ 3.6.14 from
# https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v3_6_14/
RUN printf '\n\n\n'; figlet -t -- ' RABBITMQ  *  3.6' \
  && rabbit_file=rabbitmq-server_3.6.14-1_all.deb \
  && apt-get update && apt-get upgrade -f -y \
  && apt-get install -y erlang-nox logrotate socat \
  && rabbit_file=rabbitmq-server_3.6.14-1_all.deb \
  && wget -O \$rabbit_file https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v3_6_14/\$rabbit_file \
  && dpkg -i \$rabbit_file \
  && apt-get -y -f install \
  && mkdir -p /etc/rabbitmq && (echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config) \
  && service rabbitmq-server restart \
  && rabbitmqctl set_vm_memory_high_watermark 0.1 \
  && rabbitmq-plugins enable rabbitmq_management \
  && service rabbitmq-server stop \
  && rm -f \$rabbit_file && apt-get clean



ENTRYPOINT bash entry.sh

_Dockerfile_

cat << _MySQL_ > .my.cnf
[mysqld]
max_allowed_packet = 128M
innodb_buffer_pool_size = 1M
table_cache = 256
query_cache_size = 1M
character_set_server = utf8
collation_server = utf8_general_ci
key_buffer_size = 1M
bind-address = 0.0.0.0

# log-error = /var/lib/mysql/logs/mysql-error.log
# log-slow-queries = /var/lib/mysql/logs/mysql-slowquery.log
_MySQL_

echo '#!/bin/bash
echo Starting 5 Services; \
  echo Starting netdata ...; \
  /opt/netdata/bin/netdata; \
  service postgresql start; \
  service redis-server start; \
  service mysql start; \
  service rabbitmq-server start; \
  service mongodb-server start; \
  service ssh start; \
  echo Enjoy the simplest monitor below :\)

while true; do 
  ps axc > svc
  list="|"
  for s in sshd mysqld mongod rabbitmq-server postgres redis-server; do
    list="$list $s"
    if [ -z "$(cat svc | grep $s)" ]; then list="$list: -- | "; else list="$list: ON | "; fi
  done
  echo $(date) $list
  sleep 3; 
done;
' > entry.sh
chmod +x entry.sh



echo '#!/bin/sh
### BEGIN INIT INFO
# Provides:          mongod
# Required-Start:    $network $local_fs $remote_fs
# Required-Stop:     $network $local_fs $remote_fs
# Should-Start:      $named
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: An object/document-oriented database
# Description:       MongoDB is a data store 
### END INIT INFO

case "$1" in
  start)
      echo Starting MogoDB 3.4 ...
      mkdir -p /var/lib/mongodb/data; mkdir -p /var/log/mongodb; \
      (rm -f /var/lib/mongodb/data/mongod.lock || true); \
      (nohup mongod --bind_ip 0.0.0.0 --port 27017 --dbpath /var/lib/mongodb/data --journal --smallfiles --nssize 8 --wiredTigerCacheSizeGB 1 --logpath /var/log/mongod.log > /var/log/mongodb-startup.log 2>&1 & ) ;
      sleep 1
    ;;
  stop)
      echo shutting down MogoDB 3.4 ...
      killall mongod
      sleep 1
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
esac
' > mongodb-server
chmod +x mongodb-server



docker rm -f server || true
docker rmi servers || true
time (sudo docker build -t servers . | tee image-build.log)
