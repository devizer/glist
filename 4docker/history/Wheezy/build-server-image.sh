#!/bin/bash
cat << _Dockerfile_ > Dockerfile

# help: https://cloud.google.com/appengine/docs/flexible/dotnet/customizing-the-dotnet-runtime
FROM debian:jessie
COPY . /app
WORKDIR /app
EXPOSE 3306
EXPOSE 5432
EXPOSE 6397
ENV ASPNETCORE_URLS=http://+:8080

# RUN (echo '#!/bin/bash' > /usr/sbin/policy-rc.d)

# pre-intall regular tools
RUN mkdir -p /root && cd /root \
  && (apt-get update && apt-get install wget less xz-utils p7zip-full sudo procps binutils -y || true) && apt-get clean 

# pre-intall: FFMPEG latest
RUN # \
  && wget --no-check-certificate -O ffmpeg-release-64bit-static.tar.xz https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-64bit-static.tar.xz \
  && time (tar -xJf ffmpeg-release-64bit-static.tar.xz) \
  && cd ffmpeg* \
  && d=\$(pwd) \
  && cp ff* /usr/bin \
  && cd .. \
  && rm -rf "\$d" && ffprobe -version

# pre-install MySQL Server 5.5 with root's password=root
# mysql --user=root --password=root --host=127.0.0.1 --port=3306 -e 'Show Variables Like "%VERSION%";'
RUN echo -e "\n\nINSTALLING MYSQL 5.5" \
  && (echo mysql-server-5.5 mysql-server/root_password password root | debconf-set-selections) \
  && (echo mysql-server-5.5 mysql-server/root_password_again password root | debconf-set-selections) \
  && (apt-get -y install mysql-server-5.5 && service mysql start) \
  && (echo -e '[mysqld]\nmax_allowed_packet=128M \ninnodb_buffer_pool_size=1M \ntable_cache= 256 \nquery_cache_size= 1M \ncharacter_set_server = utf8 \nkey_buffer_size=1M \nbind-address = 0.0.0.0' >> /etc/mysql/my.cnf) && service mysql restart \
  && echo MySQL VERSION && mysql --user=root --password=root -e 'Show Variables Like "%VERSION%";' \
  && service mysql stop && apt-get clean

# pre-install REDIS server 2.8
RUN echo -e "\n\nINSTALLING REDIS SERVER 2.8" \
  && apt-get -y install redis-server \
  && (echo maxmemory 100M >> /etc/redis/redis.conf) \
  && service redis-server restart \
  && echo REDIS \$(echo info | redis-cli | grep redis_version) \
  && service redis-server stop && apt-get clean

# pre-install RabbitMQ 3.6.14 from
# https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v3_6_14/
RUN rabbit_file=rabbitmq-server_3.6.14-1_all.deb \
  && apt-get update && apt-get upgrade -f -y \
  && apt-get install -y erlang-nox logrotate socat \
  && rabbit_file=rabbitmq-server_3.6.14-1_all.deb \
  && wget -O \$rabbit_file https://github.com/rabbitmq/rabbitmq-server/releases/download/rabbitmq_v3_6_14/\$rabbit_file \
  && dpkg -i \$rabbit_file \
  && apt-get -y -f install \
  && service rabbitmq-server start \
  && rabbitmqctl set_vm_memory_high_watermark 0.1 \
  && rabbitmq-plugins enable rabbitmq_management \
  && service rabbitmq-server stop \
  && rm -f \$rabbit_file && apt-get clean

# ENTRYPOINT ["dotnet", "Gallery.MVC.dll"]
ENTRYPOINT bash -c '(service redis-server start || true); (service mysql start || true); (service rabbitmq-server start || true); while true; do sleep 1; done;'
# ENTRYPOINT bash -c 'dotnet Gallery.MVC.dll;'

_Dockerfile_

sudo docker build -t servers .
