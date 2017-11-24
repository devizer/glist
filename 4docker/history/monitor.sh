while true; do 
  ps axc > svc
  list="|"
  for s in mysqld mongod rabbitmq-server postgres redis-server; do
    list="$list $s"
    if [ -z "$(cat svc | grep $s)" ]; then list="$list: -- | "; else list="$list: ON | "; fi
  done
  echo $list
  sleep 3; 
done;
