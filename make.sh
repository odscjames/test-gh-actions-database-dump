#/bin/bash

set -e

# Create a shared docker network
docker network create -d bridge test-database-dump-mysql

# Start a Postgres server
docker run -d --name test-database-dump-mysql -e MYSQL_ROOT_PASSWORD=1234  --publish 13306:3306/tcp -d  \
  --network=test-database-dump-mysql  --network-alias=server   mysql:8.0

# Wait till server has started
# TODO: Do better than this
sleep 20

# Create a database
docker run --rm --network test-database-dump-mysql mysql:8.0 \
  mysql -h server -P 3306 -u root -p1234 -e "CREATE DATABASE test"

# Create a table
docker run --rm --network test-database-dump-mysql mysql:8.0 \
  mysql -h server -P 3306 -u root -p1234 -D test -e "CREATE TABLE foo ( id INTEGER PRIMARY KEY )"

# Dump
docker run --rm --network test-database-dump-mysql  \
  --mount type=bind,source="$(pwd)"/database,target=/database mysql:8.0 \
  mysqldump -h server -P 3306 -u root -p1234 --result-file=/database/database.sql --no-data test

# Remove dumped lines
sed -i '/^\-\- Dump completed on/d' database/database.sql
sed -i '/^\-\- Server version/d' database/database.sql
sed -i '/^\-\- Host/d' database/database.sql
sed -i '/^\-\- MySQL dump/d' database/database.sql