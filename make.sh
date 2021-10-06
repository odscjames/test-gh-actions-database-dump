#/bin/bash

set -e

# Create a shared docker network
docker network create -d bridge test-database-dump-mssqlserver

# Start a Postgres server
docker run -d --name test-database-dump-mssqlserver -e "ACCEPT_EULA=Y" -e "SA_PASSWORD=1234abAB"  --publish 11433:1433/tcp -d  \
  --network=test-database-dump-mssqlserver  --network-alias=server   mcr.microsoft.com/mssql/server:2019-CU13-ubuntu-20.04

# Wait till server has started
# TODO: Do better than this
sleep 20

# Create a database
# TODO: Ideally I would specify a tag for this docker image but the MS docs are broken so I can't list them!
docker run --rm --network test-database-dump-mssqlserver \
  mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd -S server,1433 -U SA -P 1234abAB -q "CREATE DATABASE test"

# Create a table
docker run --rm --network test-database-dump-mssqlserver \
  mcr.microsoft.com/mssql-tools \
  /opt/mssql-tools/bin/sqlcmd -S server,1433 -U SA -P 1234abAB -d test -q "CREATE TABLE foo ( id INTEGER PRIMARY KEY )"

# Dump
docker run --rm --network test-database-dump-mssqlserver --mount type=bind,source="$(pwd)"/database,target=/database  \
  ubuntu:20.04 \
  /bin/bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y python3 python3-pip libicu66 libssl1.1 libffi-dev libunwind8 && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && pip3 install mssql-scripter && mssql-scripter -S server,1433 -U SA -P 1234abAB -d test > /database/database.sql"
# THIS DONT WORK
# https://github.com/microsoft/mssql-scripter/issues/236 SUGGEST SOME TERRIBLE WORK AROUNDS

# Remove dumped lines
sed -i '/^\-\- Dumped by /d' database/database.sql
sed -i '/^\-\- Dumped from /d' database/database.sql
