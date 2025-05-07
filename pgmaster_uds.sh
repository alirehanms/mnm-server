#!/bin/bash

set -e

# Configuration
PG_CONTAINER_NAME="pg-master"
PG_VERSION="16"
PG_PASSWORD="masterpass"
REPL_USER="replicator"
REPL_PASSWORD="replpass"
PGDATA_DIR="/srv/pgdata"
SOCKET_DIR="/srv/sockets/postgres"

# Create necessary directories
echo "Creating directories..."
mkdir -p "$PGDATA_DIR" "$SOCKET_DIR"
chown 999:999 "$PGDATA_DIR" "$SOCKET_DIR"
chmod 700 "$PGDATA_DIR" "$SOCKET_DIR"

# Remove existing container if exists
if podman container exists $PG_CONTAINER_NAME; then
  echo "Removing existing container..."
  podman rm -f "$PG_CONTAINER_NAME"
fi

# Run PostgreSQL container
echo "Starting PostgreSQL container..."
podman run -d \
  --name "$PG_CONTAINER_NAME" \
  -e POSTGRES_PASSWORD="$PG_PASSWORD" \
  -e PGDATA="/var/lib/postgresql/data" \
  -v "$PGDATA_DIR:/var/lib/postgresql/data:Z" \
  -v "$SOCKET_DIR:/var/run/postgresql:Z" \
  docker.io/library/postgres:$PG_VERSION

# Wait for container to start
echo "Waiting for PostgreSQL to be ready..."
sleep 5

# Configure PostgreSQL for socket-only, logical replication
echo "Configuring postgresql.conf and pg_hba.conf..."
podman exec "$PG_CONTAINER_NAME" bash -c "
echo \"
listen_addresses = ''
unix_socket_directories = '/var/run/postgresql'
wal_level = logical
max_wal_senders = 4
max_replication_slots = 4
\"
>> /var/lib/postgresql/data/postgresql.conf
"

podman exec "$PG_CONTAINER_NAME" bash -c "
echo \"
local   replication     $REPL_USER                         trust
local   all             all                                trust
\"
>> /var/lib/postgresql/data/pg_hba.conf
"

# Restart container to apply configs
echo "Restarting PostgreSQL container..."
podman restart "$PG_CONTAINER_NAME"

# Wait again
sleep 5

# Create replication user, database, and publication
echo "Setting up replication user and publication..."
podman exec -u postgres "$PG_CONTAINER_NAME" psql -v ON_ERROR_STOP=1 <<EOF
CREATE USER $REPL_USER WITH REPLICATION PASSWORD '$REPL_PASSWORD';
CREATE DATABASE mydb;
\c mydb
CREATE TABLE products (id SERIAL PRIMARY KEY, name TEXT);
INSERT INTO products (name) VALUES ('replication test');
CREATE PUBLICATION mypub FOR TABLE products;
EOF

echo "✅ PostgreSQL master setup complete."
echo "🔌 Socket path: $SOCKET_DIR/.s.PGSQL.5432"
