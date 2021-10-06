#/bin/bash

# We don't use set -e because if one errors we still want the others cleaned up.

# Remove server
docker stop test-database-dump-postgres
docker rm test-database-dump-postgres

# Remove network
docker network rm test-database-dump
