#/bin/bash

# We don't use set -e because if one errors we still want the others cleaned up.

# Remove server
docker stop test-database-dump-mssqlserver
docker rm test-database-dump-mssqlserver

# Remove network
docker network rm test-database-dump-mssqlserver
