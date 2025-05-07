#!/bin/bash
set -e
source ./env.sh

echo "🔍 Checking and installing PostgreSQL if not present..."
if ! command -v psql >/dev/null; then
  apt update && apt install -y postgresql-$PG_VERSION postgresql-client-$PG_VERSION
fi

echo "🔍 Detecting PostgreSQL data directory..."
PGDATA=$(sudo -u postgres psql -t -c "SHOW data_directory;" | xargs)

echo "🛑 Stopping PostgreSQL and clearing old data directory..."
systemctl stop postgresql || true
rm -rf "$PGDATA"

echo "📥 Taking base backup from Primary..."
PGPASSWORD=$REPL_PASSWORD pg_basebackup -h $PRIMARY_HOST -D "$PGDATA" -U $REPL_USER -P --wal-method=stream

echo "🔧 Creating standby.signal file..."
touch "$PGDATA/standby.signal"

echo "⚙️ Creating primary_conninfo..."
cat >> "$PGDATA/postgresql.auto.conf" <<EOF
primary_conninfo = 'host=$PRIMARY_HOST port=5432 user=$REPL_USER password=$REPL_PASSWORD application_name=readonly'
EOF

chown -R postgres:postgres "$PGDATA"

echo "🚀 Starting PostgreSQL..."
systemctl start postgresql

echo "✅ Read-only server configured successfully."
