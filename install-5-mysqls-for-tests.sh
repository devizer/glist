#!/us/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/install-5-mysqls-for-tests.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash
set -e
set -u

function wait_for() {
  n=$1
  p=$2
  printf "\nWaiting for $n on localhost @ $p ...."
  counter=0; total=30; started=""
  while [ $counter -lt $total ]; do
    counter=$((counter+1));
    mysql --protocol=TCP -h localhost -u root -p'D0tN3t' -P $p -e "Select 1;" 2>/dev/null 1>&2 && started="yes" || true
    if [ -n "$started" ]; then printf " OK\n"; break; else (sleep 1; printf $counter"."); fi
  done
}

images=("vsamov/mysql-5.1.73" "mysql/mysql-server:5.5" "mysql/mysql-server:5.6" "mysql/mysql-server:5.7" "mysql/mysql-server:8.0")
names=("mysql-5.1" "mysql-5.5" "mysql-5.6" "mysql-5.7" "mysql-8.0")
count=${#images[@]}
echo "COUNT: $count"
for (( i=0; i<$count; i++ )); do
  image=${images[$i]}
  name=${names[$i]}
  echo "[$(($i+1)) / $count] container: $name, image: $image"
  time sudo docker pull "$image"
  port=$((3306+1+$i));
  cmd="sudo docker run --name $name -e MYSQL_ROOT_HOST=% -e MYSQL_ROOT_PASSWORD=D0tN3t -e MYSQL_DATABASE=w3top -d -p $port:3306 $image"
  echo ""; echo $cmd
  eval "$cmd" || true
  # sleep 8; docker logs $name
  wait_for "$name" "$port"
  mysql --protocol=TCP -h localhost -u root -p'D0tN3t' -P $port -e "Select version() as \`MySQL Server at $port port\`; show databases;"
  echo ""
done
