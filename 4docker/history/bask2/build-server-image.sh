#!/bin/bash

cat << _Dockerfile_ > Dockerfile
# help: https://cloud.google.com/appengine/docs/flexible/dotnet/customizing-the-dotnet-runtime
FROM debian:jessie
COPY . /app
WORKDIR /app
SHELL ["bash", "-c"]

# MySQL
EXPOSE 3306

# PostgreSQL
EXPOSE 5432

# REDIS
EXPOSE 6397

# RabbitMQ
EXPOSE 5672 15672

# MongoDB
EXPOSE 27017

ENV ASPNETCORE_URLS=http://+:8080

# RUN (echo '#!/bin/bash' > /usr/sbin/policy-rc.d)

# pre-intall regular tools
RUN apt-get update && apt-get install wget less xz-utils p7zip-full sudo procps binutils -y && apt-get clean 

# pre-install mongodb-server 3.4
RUN echo -e "\n\nINSTALLING MongoDB 3.4" \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 \
  && echo "deb http://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" > /etc/apt/sources.list.d/mongodb-org-3.4.list \
  && apt-get update && apt-get install -y mongodb-org-server \
  && apt-get clean


# pre-intall: FFMPEG latest
RUN echo -e "\n\nINSTALLING FFMPEG Latest" \
  && wget --no-check-certificate -O ffmpeg-release-64bit-static.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-64bit-static.tar.xz \
  && time (tar -xJf ffmpeg-release-64bit-static.tar.xz) \
  && cd ffmpeg* \
  && d=\$(pwd) \
  && cp ff* /usr/bin \
  && cd .. && rm -rf "\$d" && rm -f ffmpeg-release-64bit-static.tar.xz \
  && echo -e "\n\nFFPROBE VERSION" && ffprobe -version


# pre-install REDIS server 2.8
RUN echo -e "\n\nINSTALLING REDIS SERVER 2.8" \
  && apt-get -y install redis-server \
  && (echo -e "\nmaxmemory 100M\nbind 0.0.0.0" >> /etc/redis/redis.conf) \
  && service redis-server restart \
  && echo REDIS \$(echo info | redis-cli | grep redis_version) \
  && service redis-server stop && apt-get clean


# pre-install MySQL Server 5.5 with root's password=root.
# network access: --user=mysql --password=mysql
# mysql --user=root --password=root --host=127.0.0.1 --port=3306 -e 'Show Variables Like "%VERSION%";'
RUN echo -e "\n\nINSTALLING MYSQL 5.5" \
  && (echo mysql-server-5.5 mysql-server/root_password password root | debconf-set-selections) \
  && (echo mysql-server-5.5 mysql-server/root_password_again password root | debconf-set-selections) \
  && (apt-get -y install mysql-server-5.5 && service mysql start) \
  && (echo -e '\n[mysqld]\nmax_allowed_packet=128M \ninnodb_buffer_pool_size=1M \ntable_cache= 256 \nquery_cache_size= 1M \ncharacter_set_server = utf8 \nkey_buffer_size=1M \nbind-address = 0.0.0.0' >> /etc/mysql/my.cnf) && service mysql restart \
  && echo MySQL VERSION && mysql --user=root --password=root -e 'Show Variables Like "%VERSION%";' \
  && mysql --user=root --password=root -e "CREATE USER 'mysql'@'%' IDENTIFIED BY 'mysql'; GRANT ALL PRIVILEGES ON *.* TO 'mysql'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;" \
  && service mysql stop && apt-get clean

# Peer authentication failed for user "postgre"?
RUN echo -e "\n\nINSTALLING Postgre 9.4" \
  && (apt-get -y install postgresql) \
  && (echo -e "\nlisten_addresses = '*' " >> /etc/postgresql/9.4/main/postgresql.conf) \
  && (echo -e "\n\nlocal all all  trust\nhost all all 255.255.255.255/0 trust" >  /etc/postgresql/9.4/main/pg_hba.conf) \
  && service postgresql restart \
  && echo -e "\n\nPOSTGRESQL VERSION: " && psql postgres postgres -c 'SELECT Version();' \
  && service postgresql stop && apt-get clean


# pre-install RabbitMQ 3.6.14 from
# https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v3_6_14/
RUN echo -e "\n\nINSTALLING Rabbit MQ Server 3.6" \
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
key_buffer_size = 1M
bind-address = 0.0.0.0
_MySQL_

echo '
echo Starting 5 Services; \
  service postgresql start; \
  service redis-server start; \
  service mysql start; \
  service rabbitmq-server start; \
  mkdir -p /var/lib/mongodb/data; \
  echo Starting Mongo DB Server; \
  (rm -f /var/lib/mongodb/data/mongod.lock || true); \
  (nohup mongod --bind_ip 0.0.0.0 --port 27017 --dbpath /var/lib/mongodb/data --journal --smallfiles --nssize 8 --wiredTigerCacheSizeGB 1 --logpath /var/log/mongod.log > /var/log/mongodb.log & ); 

while true; do 
  ps axc > svc
  list="|"
  for s in mysqld mongod rabbitmq-server postgres redis-server; do
    list="$list $s"
    if [ -z "$(cat svc | grep $s)" ]; then list="$list: -- | "; else list="$list: ON | "; fi
  done
  echo $(date) $list
  sleep 3; 
done;
' > entry.sh
chmod +x entry.sh

docker rm -f server || true
docker rmi servers || true
time (sudo docker build -t servers .)
