#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/install-5-mysqls-for-tests-V2.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash
set -e
set -u

MYSQL_TEST_DB="${MYSQL_TEST_DB:-APP42}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-D0tN3t}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-30}"

function wait_for_mysql() {
local name=$1 port=$2
  printf "Waiting for $name on port $port ..."
  counter=0; total=$WAIT_TIMEOUT; started=""
  while [ $counter -lt $total ]; do
    counter=$((counter+1));
    # mysql --protocol=TCP -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" -P $p -e "Select 1;" 2>/dev/null 1>&2 && started="yes" || true
    docker exec -t $name mysql --protocol=TCP -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" -P 3306 -e "Select 1;" 2>/dev/null 1>&2 && started="yes" || true
    if [ -n "$started" ]; then printf " OK"; break; else (sleep 1; printf $counter"."); fi
  done
  if [ -z "$started" ]; then printf " Fail\n"; else
    ver=$(docker exec -t $name sh -c "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -s -N --protocol=TCP -h localhost -u root -P 3306 -e 'Select version();' 2>&1")
    echo ", Ver is $ver"
  fi
}

function wait_for_mysql_prev() {
local name=$1 port=$2
  printf "Waiting for $name on port $port ..."
  counter=0; total=$WAIT_TIMEOUT; started=""
  while [ $counter -lt $total ]; do
    counter=$((counter+1));
    # mysql --protocol=TCP -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" -P $p -e "Select 1;" 2>/dev/null 1>&2 && started="yes" || true
    docker exec -t $name mysql --protocol=TCP -h localhost -u root -p"${MYSQL_ROOT_PASSWORD}" -P 3306 -e "Select 1;" 2>/dev/null 1>&2 && started="yes" || true
    if [ -n "$started" ]; then printf " OK\n"; break; else (sleep 1; printf $counter"."); fi
  done
  if [ -z "$started" ]; then printf " Fail\n"; fi;
}

images=("vsamov/mysql-5.1.73" "mysql/mysql-server:5.5" "mysql/mysql-server:5.6" "mysql/mysql-server:5.7" "mysql/mysql-server:8.0")
names=("mysql-5.1" "mysql-5.5" "mysql-5.6" "mysql-5.7" "mysql-8.0")
count=${#images[@]}
echo "Installing $count mysql servers: ${names[*]// /|}"
for (( i=0; i<$count; i++ )); do
  image=${images[$i]}
  name=${names[$i]}
  echo "[$(($i+1)) / $count] starting container [$name] using image [$image]"
  time sudo bash -c "TIMEFORMAT='Image download time: %1lR' docker pull $image"
  port=$((3306+1+$i));
  cmd="sudo docker run --name $name -e MYSQL_ROOT_HOST=% -e MYSQL_ROOT_PASSWORD=\"${MYSQL_ROOT_PASSWORD}\" -e MYSQL_DATABASE=\"${MYSQL_TEST_DB}\" -d -p $port:3306 $image || docker start $name"
  echo ""; echo $cmd
  eval "$cmd" || true
done

echo "Waiting $count mysql servers for readiness [${names[*]// /|}]"
for (( i=0; i<$count; i++ )); do
  image=${images[$i]}
  name=${names[$i]}
  port=$((3306+1+$i));
  wait_for_mysql "$name" "$port"
done

echo "Checking $count mysql servers: ${names[*]// /|}"
for (( i=0; i<$count; i++ )); do
  image=${images[$i]} name=${names[$i]} port=$((3306+1+$i));
  ver=$(docker exec -t $name sh -c "MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\" mysql -s -N --protocol=TCP -h localhost -u root -P 3306 -e 'Select version();' 2>&1")
  echo "MySQL server version on port [$port] is [$ver]";
done
