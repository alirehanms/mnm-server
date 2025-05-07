#!/bin/bash
set -e

# Paths
DATA_DIR="$PWD/postgres_data"
SOCKET_DIR="$PWD/shared_socket"
PGBOUNCER_SOCKET_DIR="$SOCKET_DIR/pgbouncer"
POSTGRES_SOCKET_DIR="$SOCKET_DIR/postgresql"

# Ensure necessary directories exist
mkdir -p "$DATA_DIR"
mkdir -p "$PGBOUNCER_SOCKET_DIR"
mkdir -p "$POSTGRES_SOCKET_DIR"
chmod -R 777 "$SOCKET_DIR"  # Adjust in production for security

# Pull images
podman pull docker.io/library/postgres:15
podman pull docker.io/edoburu/pgbouncer

# Stop and remove existing containers if they exist
podman rm -f pg || true
podman rm -f pgbouncer || true

# Start PostgreSQL
podman run -d \
  --name pg \
  -e POSTGRES_USER=svc_a_user \
  -e POSTGRES_PASSWORD=none \
  -e PGDATA=/var/lib/postgresql/data \
  -v "$DATA_DIR":/var/lib/postgresql/data:Z \
  -v "$POSTGRES_SOCKET_DIR":/var/run/postgresql:Z \
  --tmpfs /run/postgresql \
  --userns=keep-id \
  postgres:15 \
  -c listen_addresses='' \
  -c unix_socket_directories='/var/run/postgresql'

echo "Waiting for PostgreSQL to start..."
sleep 5

# Create pgBouncer userlist.txt
cat <<EOF > userlist.txt
"svc_a_user" ""
EOF

# Create pgBouncer INI
cat <<EOF > pgbouncer.ini
[databases]
svc_a_db = host=/var/run/postgresql dbname=postgres

[pgbouncer]
listen_port = 6432
auth_type = hba
auth_hba_file = /etc/pgbouncer/pg_hba.conf
auth_file = /etc/pgbouncer/userlist.txt
unix_socket_dir = /var/run/pgbouncer
unix_socket_mode = 0777
logfile = /dev/stdout
pidfile = /tmp/pgbouncer.pid
EOF

# Create pg_hba.conf for pgBouncer
cat <<EOF > pg_hba.conf
local all svc_a_user peer
EOF

# Start pgBouncer
podman run -d \
  --name pgbouncer \
  -v "$PGBOUNCER_SOCKET_DIR":/var/run/pgbouncer:Z \
  -v "$POSTGRES_SOCKET_DIR":/var/run/postgresql:Z \
  -v "$PWD/pgbouncer.ini":/etc/pgbouncer/pgbouncer.ini:Z \
  -v "$PWD/userlist.txt":/etc/pgbouncer/userlist.txt:Z \
  -v "$PWD/pg_hba.conf":/etc/pgbouncer/pg_hba.conf:Z \
  --tmpfs /tmp \
  --userns=keep-id \
  edoburu/pgbouncer

echo "✅ PostgreSQL and pgBouncer containers are up and running using Unix socket peer authentication."
