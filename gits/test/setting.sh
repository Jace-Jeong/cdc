#!/bin/bash



#IP=`docker inspect jmx_postgres_1 | grep IPAddress | grep 172 | tr -d ':,", ,IPAddress'`

#if [ "${IP}" = "" ] ; then
#	echo "input ip address!"
#	exit 1
#fi

#################################################################################
# docker 실행
PWD=`pwd`
docker-compose -f $PWD/docker-compose.yml up -d
echo "docker up complete!"


echo "wait 5 seconds!"
sleep 5s

#################################################################################
# DB setting
docker cp ./scripts/run.sh jmx_postgres_1:/var/lib/postgresql/run.sh
docker cp ./scripts/run_db.sql jmx_postgres_1:/var/lib/postgresql/run_db.sql
docker exec -u postgres jmx_postgres_1 /var/lib/postgresql/run.sh
echo 	"create inventory database !"

docker cp ./scripts/ojdbc8.jar jmx_connect_1:/kafka/libs/ojdbc8.jar
docker cp ./scripts/xstreams.jar jmx_connect_1:/kafka/libs/xstreams.jar


# run connect download
docker cp ./scripts/run_connect.sh jmx_connect_1:/kafka/run_connect.sh
docker exec jmx_connect_1 /kafka/run_connect.sh
docker restart jmx_connect_1

#################################################################################
# 30 second i
echo "wait 5 seconds!"
sleep 5s

#################################################################################
IP=`docker inspect jmx_postgres_1 | grep IPAddress | grep 172 | tr -d ':,", ,IPAddress'`
echo $IP
#################################################################################
# connection 연결

curl -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/ -d '
{
     "name": "inventory-connector",
    "config": {
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "tasks.max": "1",
        "database.hostname": "'$IP'",
        "database.port": "'$JMX_POSTGRES_INNER_PORT'",
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
        "transforms.route.replacement": "$3"
    }
}' | jq

echo 	" create connector!"

#################################################################################
# DB setting
docker cp ./scripts/run_2.sh jmx_postgres_1:/var/lib/postgresql/run_2.sh
docker cp ./scripts/run_db_2.sql jmx_postgres_1:/var/lib/postgresql/run_db_2.sql
docker exec -u postgres jmx_postgres_1 /var/lib/postgresql/run_2.sh
echo 	"insert into dumb table!"

#################################################################################
# 오라클 연결
# crul
#################################################################################
#CONNECT_IP=`docker inspect jmx_connect_1 | grep IPAddress | grep 172 | tr -d ':,", ,IPAddress'`
ORACLE_IP=`docker inspect jmx_oracle_1 | grep IPAddress | grep 172 | tr -d ':,", ,IPAddress'`

curl -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/ -d '
{
    "name": "jdbc-sink-oracle",
    "config": {
        "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
        "tasks.max": "1",
        "topics": "dumb_table",
        "connection.url": "jdbc:oracle:thin:@'$ORACLE_IP':1521:xe",
        "connection.user": "system",
        "connection.password": "oracle",
        "transforms": "unwrap",
        "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
        "transforms.unwrap.drop.tombstones": "false",
        "auto.create": "true",
        "insert.mode": "upsert",
        "delete.enabled": "true",
        "pk.fields": "id",
        "pk.mode": "record_key"
    }
}' | jq

echo "create oracle jdbc sync connect!"


#################################################################################
# 30 second i
echo "wait 5 seconds!"
sleep 5s
#################################################################################
# DB insert
docker cp ./scripts/run_3.sh jmx_postgres_1:/var/lib/postgresql/run_3.sh
docker exec -u postgres jmx_postgres_1 /var/lib/postgresql/run_3.sh
echo 	"insert into dumb table!"

#################################################################################
curl -H 'Accept:application/json' localhost:8083/connectors
echo 	"check connect!"


#################################################################################
#echo 	"consumer ! "
#$PWD/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic dbserver1.public.dumb_table --from-beginning
#################################################################################
#echo 	"connect DB!"
docker exec -itu postgres  jmx_postgres_1 bash
