#!/usr/bin/env bash
# url=https://raw.githubusercontent.com/devizer/glist/master/install-7-postres-for-tests.sh; (wget -q -nv --no-check-certificate -O - $url 2>/dev/null || curl -sSL $url) | bash
set -e
set -u

POSTGRESQL_DB="${POSTGRESQL_DB:-APP42}"
POSTGRESQL_PASS="${POSTGRESQL_PASS:-pass}"
POSTGRESQL_USER="${POSTGRESQL_USER:-postgres}"
WAIT_TIMEOUT="${WAIT_TIMEOUT:-30}"

function wait_for_pgsql() {
  local port=$1 total=$WAIT_TIMEOUT counter=0 started=""
  if [[ "$(command -v psql)" == "" ]]; then return; fi
  printf "Waiting for postgres on localhost at $port port ...."
  counter=0; total=$WAIT_TIMEOUT; started=""
  while [ $counter -lt $total ]; do
    counter=$((counter+1));
    PGCONNECT_TIMEOUT=1 PGPASSWORD="$POSTGRESQL_PASS" psql -t -h localhost -p "$port" -U "$POSTGRESQL_USER" -q -c "select 1;" >/dev/null 2>&1 && started="yes" || true
    if [ -n "$started" ]; then printf " OK\n"; break; else (sleep 1; printf $counter"."); fi
  done
  if [ -z "$started" ]; then printf " Fail\n"; fi;
}

vars="-e POSTGRESQL_USER=$POSTGRESQL_USER -e POSTGRESQL_PASS=$POSTGRESQL_PASS -e POSTGRES_PASSWORD=$POSTGRESQL_PASS -e POSTGRESQL_PASSWORD=$POSTGRESQL_PASS -e POSTGRES_DB=$POSTGRESQL_DB"

# 1: 12     ?
# 2: 11.4
# 3: 10.9
# 4: 9.6    ?
# 5: 9.5    ?
# 6: 9.4    ?
# 7: 9.1
# 8: 8.4
port=54321; counter=0; total=8
for image in postgres:12-alpine postgres:11.4-alpine postgres:10.9-alpine postgres:9.6-alpine postgres:9.5-alpine postgres:9.4-alpine postgres:9.1 postgres:8.4; do
  name="${image//:/-}"
  counter=$((counter+1))
  echo ""; echo "[$counter / $total] Starting '$image' image as '$name' container"
  exists=false
  sudo docker logs "$name" >/dev/null 2>&1 && echo $name already exists && exists=true && sudo docker start $name >/dev/null 2>&1
  if [[ $exists == false ]]; then
    if [[ -n "${HIDE_PULL_PROGRESS:-}" ]]; then hide_pull=">/dev/null"; fi
    pgcmd="sudo docker pull $image ${hide_pull:-}; sudo docker run --name $name $vars -p ${port}:5432 -d $image"
    echo "shell command for $name"; echo "-| $pgcmd"
    time eval "$pgcmd"
  fi
  port=$((port+1))
done

for port in {54328..54321}; do
  wait_for_pgsql $port
done

for port in {54321..54328}; do
  printf "checking port $port ...";
  cmd1='PGPASSWORD='$POSTGRESQL_PASS' psql -t -h localhost -p '$port' -U postgres -q -c "select version();"';
  v1="unknown"; v1=$(eval $cmd1 || true); v1="${v1## }";
  cmd2='PGPASSWORD='$POSTGRESQL_PASS' psql -t -h localhost -p '$port' -U postgres -q -c "show server_version;"';
  v2="unknown"; v2=$(eval $cmd2 || true); v2="${v2## }";
  printf "\r$port: [$v2] $v1\n";
done
