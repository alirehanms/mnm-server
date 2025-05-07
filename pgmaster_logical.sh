#!/bin/bash

# Configurable variables
PG_CONTAINER_NAME="pg-master"
PG_USER="replicator"
PG_PASSWORD="replpass"
PG_DATABASE="mydb"
PG_PUBLICATION="mypub"
PG_SLOT="mysub"
PG_TABLESPACE_DIR="/mnt/tablespaces/ts1"
PG_CONTAINER_PORT="5432"
PG_DATA_DIR="/var/lib/postgresql/data"
PG_MASTER_IP="pg-master-ip"  # Replace with the actual IP address

# Create the tablespace directory on the host
echo "Creating tablespace directory on the host..."
mkdir -p ${PG_TABLESPACE_DIR}
chmod 700 ${PG_TABLESPACE_DIR}

# Start the pg-master container (Podman)
echo "Starting pg-master container..."
podman run -d --name ${PG_CONTAINER_NAME} \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p ${PG_CONTAINER_PORT}:${PG_CONTAINER_PORT} \
  -v ${PG_DATA_DIR}:${PG_DATA_DIR}:Z \
  -v ${PG_TABLESPACE_DIR}:${PG_TABLESPACE_DIR}:Z \
  docker.io/library/postgres:16

# Wait for the container to be ready
echo "Waiting for pg-master container to be ready..."
sleep 10

# Connect to the pg-master container and create replication user and tablespace
echo "Creating replication user and tablespace on pg-master..."
podman exec -it ${PG_CONTAINER_NAME} psql -U postgres -c \
  "CREATE USER ${PG_USER} WITH REPLICATION PASSWORD '${PG_PASSWORD}';"
podman exec -it ${PG_CONTAINER_NAME} psql -U postgres -c \
  "CREATE DATABASE ${PG_DATABASE};"
podman exec -it ${PG_CONTAINER_NAME} psql -U postgres -d ${PG_DATABASE} -c \
  "CREATE TABLESPACE ts1 LOCATION '${PG_TABLESPACE_DIR}'"

# Allow replication connections from pg-subscriber
echo "Allowing replication connections from pg-subscriber..."
podman exec -it ${PG_CONTAINER_NAME} bash -c \
  "echo 'host replication ${PG_USER} pg-subscriber-ip/32 md5' >> /var/lib/postgresql/data/pg_hba.conf"

# Restart the container to apply the changes
echo "Restarting pg-master container..."
podman restart ${PG_CONTAINER_NAME}

# Create a publication for replication
echo "Creating publication on pg-master..."
podman exec -it ${PG_CONTAINER_NAME} psql -U postgres -d ${PG_DATABASE} -c \
  "CREATE PUBLICATION ${PG_PUBLICATION} FOR ALL TABLES;"

# Create a replication slot
echo "Creating replication slot on pg-master..."
podman exec -it ${PG_CONTAINER_NAME} psql -U postgres -d ${PG_DATABASE} -c \
  "SELECT pg_create_physical_replication_slot('${PG_SLOT}');"

echo "pg-master setup completed successfully!"
