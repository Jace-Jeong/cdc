#!/bin/bash

curl -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/ -d '
{
    "name": "inventory-connector",
    "config": {
        "connector.class":"io.debezium.connector.postgresql.PostgresConnector",
        "tasks.max": "1",
        "database.hostname":"172.28.0.3",
        "database.port": "5432",
        "database.user": "postgres",
        "database.password": "postgres",
        "database.dbname" : "inventory",
        "database.server.name": "dbserver1",
        "table.whitelist": "public.dumb_table",
        "plugin.name": "wal2json",
        "snapshot.mode": "never",
        "transforms": "route",
        "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
        "transforms.route.regex": "([^.]+)\\.([^.]+)\\.([^.]+)",
        "transforms.route.replacement": "$3",
        "value.converter":"io.confluent.connect.avro.AvroConverter",
        "value.converter.schema.registry.url":"http://localhost:8081"
    }
}' | jq
