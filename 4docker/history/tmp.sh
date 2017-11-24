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
