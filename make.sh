#/bin/bash

set -e

# Create a shared docker network
docker network create -d bridge test-database-dump

# Start a Postgres server
docker run -d --name test-database-dump-postgres -e POSTGRES_PASSWORD=1234  --publish 54321:5432/tcp -d  \
  --network=test-database-dump  --network-alias=server   postgres:12

# Wait till server has started
# TODO: Do better than this
sleep 20

# Create a table
docker run --rm -e POSTGRES_PASSWORD=1234 --env PGPASSWORD=1234 --network test-database-dump postgres:12 \
  psql -h server -p 5432 -U postgres --no-password -d postgres -c "CREATE TABLE foo ( id INTEGER PRIMARY KEY )"

# Dump
docker run --rm -e POSTGRES_PASSWORD=1234 --env PGPASSWORD=1234 --network test-database-dump \
  --mount type=bind,source="$(pwd)"/database,target=/database   postgres:12 \
  pg_dump -h server -p 5432 -U postgres --no-password -f /database/database.sql --schema-only postgres

# Remove dumped lines
sed -i '/^\-\- Dumped by /d' database/database.sql
sed -i '/^\-\- Dumped from /d' database/database.sql
