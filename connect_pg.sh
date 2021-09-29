#!/bin/bash

docker exec -u postgres -it docker-compose_postgres_1 bash -c "psql postgres postgres"
