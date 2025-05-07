#!/bin/bash

# Configurable variables
PG_CONTAINER_NAME="pg-subscriber"
PG_USER="replicator"
PG_PASSWORD="replpass"
PG_DATABASE="mydb"
PG_PUBLICATION="mypub"
PG_SLOT="mysub"
PG_MASTER_IP="pg-master-ip"  # Replace with the actual IP address

# Start the pg-subscriber container (Podman)
echo "Starting pg-subscriber container..."
podman run -d --name ${PG_CONTAINER_NAME} \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=mysecretpassword \
  -p 5432:5432 \
  docker.io/library/postgres:16

# Wait for the container to be ready
echo "Waiting for pg-subscriber container to be ready..."
sleep 10

# Create the replication user on the subscriber
echo "Creating replication user on pg-subscriber..."
podman exec -it ${PG_CONTAINER_NAME} psql -U postgres -c \
  "CREATE USER ${PG_USER} WITH REPLICATION PASSWORD '${PG_PASSWORD}';"
podman exec -it ${PG_CONTAINER_NAME} psql -U postgres -c \
  "CREATE DATABASE ${PG_DATABASE};"

# Set up the subscription on the pg-subscriber to the pg-master
echo "Setting up subscription on pg-subscriber..."
podman exec -it ${PG_CONTAINER_NAME} psql -U postgres -d ${PG_DATABASE} -c \
  "CREATE SUBSCRIPTION ${PG_SLOT} CONNECTION 'host=${PG_MASTER_IP} port=5432 dbname=${PG_DATABASE} user=${PG_USER} password=${PG_PASSWORD}' PUBLICATION ${PG_PUBLICATION};"

# Verify subscription status
echo "Verifying subscription on pg-subscriber..."
podman exec -it ${PG_CONTAINER_NAME} psql -U postgres -d ${PG_DATABASE} -c \
  "SELECT * FROM pg_stat_subscription;"

echo "pg-subscriber setup completed successfully!"
