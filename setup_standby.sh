#!/bin/bash
set -e

# Input validation
if [[ -z "$1" ]]; then
  echo "❌ Usage: $0 <PRIMARY_IPV6_ADDRESS>"
  exit 1
fi

# Define Variables
PRIMARY_HOST="$1"  # e.g., [fd00::1]
REPL_USER="replicator"
REPL_PASSWORD="replicator_pass"
PG_VERSION=16
DATA_DIR="/var/lib/postgresql/${PG_VERSION}/main"

# Ensure PostgreSQL is installed
if ! command -v psql &> /dev/null; then
  echo "🔍 PostgreSQL not found. Installing..."
  apt update && apt install -y postgresql-${PG_VERSION}
fi

# Detect or create postgresql.conf
PG_CONF=$(find /etc/postgresql -name "postgresql.conf" 2>/dev/null | head -n 1)
if [[ -z "$PG_CONF" ]]; then
  echo "⚠️ postgresql.conf not found, creating a new one..."
  PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
  mkdir -p "$(dirname "$PG_CONF")"
  cat <<EOF > "$PG_CONF"
data_directory = '${DATA_DIR}'
hot_standby = on
EOF
else
  echo "🔍 Found postgresql.conf at $PG_CONF"
fi

# Detect or create pg_hba.conf
PG_HBA=$(find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -n 1)
if [[ -z "$PG_HBA" ]]; then
  echo "⚠️ pg_hba.conf not found, creating a new one..."
  PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"
  mkdir -p "$(dirname "$PG_HBA")"
  cat <<EOF > "$PG_HBA"
local   all             all                                     trust
host    all             all             ::0/0                   md5
host    replication     ${REPL_USER}      ::0/0                   md5
EOF
else
  echo "🔍 Found pg_hba.conf at $PG_HBA"
fi

echo "🛑 Stopping PostgreSQL..."
systemctl stop postgresql

echo "🧹 Cleaning data directory..."
rm -rf ${DATA_DIR}/*
mkdir -p ${DATA_DIR}
chown -R postgres:postgres ${DATA_DIR}

echo "📥 Performing base backup from primary..."
PGPASSWORD="${REPL_PASSWORD}" pg_basebackup -h "${PRIMARY_HOST}" -D "${DATA_DIR}" -U "${REPL_USER}" -Fp -Xs -P -R

echo "📄 Configuring replication settings..."
cat <<EOF >> ${DATA_DIR}/postgresql.auto.conf
primary_conninfo = 'host=${PRIMARY_HOST} user=${REPL_USER} password=${REPL_PASSWORD}'
synchronous_commit = off
EOF

chown -R postgres:postgres ${DATA_DIR}

echo "🚀 Starting PostgreSQL..."
systemctl start postgresql



echo "✅ Standby setup complete (IPv6-ready)."

# Final check
sleep 3
IS_REPLICA=$(sudo -u postgres psql -tAc "SELECT pg_is_in_recovery();")
if [[ "$IS_REPLICA" == "t" ]]; then
  echo "✅ Standby is correctly running in recovery (replica) mode."
else
  echo "❌ Standby is NOT in recovery mode. Check logs!"
fi