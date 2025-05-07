#!/bin/bash
set -e

# Define Variables
REPL_USER="replicator"
REPL_PASSWORD="replicator_pass"
PG_VERSION=16
DATA_DIR="/var/lib/postgresql/${PG_VERSION}/main"
WAL_ARCHIVE_DIR="/var/lib/postgresql/wal_archive"
AUTH_DB="auth"

# Get public IPv6 address (first non-link-local, non-temporary global address)
IPV6_ADDR=$(ip -6 addr show scope global | grep inet6 | grep -v 'temporary' | awk '{print $2}' | cut -d/ -f1 | head -n1)
if [[ -z "$IPV6_ADDR" ]]; then
  echo "❌ No public IPv6 address found. Exiting."
  exit 1
fi
echo "🌐 Detected public IPv6 address: $IPV6_ADDR"

# Ensure PostgreSQL is installed
if ! command -v psql &> /dev/null; then
  echo "🔍 Installing PostgreSQL ${PG_VERSION}..."
  apt update && apt install -y postgresql-${PG_VERSION}
fi

# Locate or create postgresql.conf
PG_CONF=$(find /etc/postgresql -name "postgresql.conf" 2>/dev/null | head -n 1)
if [[ -z "$PG_CONF" ]]; then
  echo "⚠️ postgresql.conf not found, creating new..."
  PG_CONF="/etc/postgresql/${PG_VERSION}/main/postgresql.conf"
  mkdir -p "$(dirname "$PG_CONF")"
  touch "$PG_CONF"
fi

# Update postgresql.conf settings to listen only on the public IPv6 address
# Remove any existing listen_addresses line and append our setting.
sed -i "/^#*\s*listen_addresses\s*=.*/d" "$PG_CONF"
echo "listen_addresses = '${IPV6_ADDR}'" >> "$PG_CONF"

# Append other replication and WAL settings
sed -i "/^#*\s*wal_level\s*=.*/d" "$PG_CONF"
echo "wal_level = replica" >> "$PG_CONF"

sed -i "/^#*\s*archive_mode\s*=.*/d" "$PG_CONF"
echo "archive_mode = on" >> "$PG_CONF"

sed -i "/^#*\s*archive_command\s*=.*/d" "$PG_CONF"
echo "archive_command = 'cp %p ${WAL_ARCHIVE_DIR}/%f'" >> "$PG_CONF"

sed -i "/^#*\s*max_wal_senders\s*=.*/d" "$PG_CONF"
echo "max_wal_senders = 10" >> "$PG_CONF"

sed -i "/^#*\s*wal_keep_size\s*=.*/d" "$PG_CONF"
echo "wal_keep_size = 128MB" >> "$PG_CONF"

sed -i "/^#*\s*hot_standby\s*=.*/d" "$PG_CONF"
echo "hot_standby = on" >> "$PG_CONF"

sed -i "/^#*\s*synchronous_commit\s*=.*/d" "$PG_CONF"
echo "synchronous_commit = off" >> "$PG_CONF"

# Locate or create pg_hba.conf
PG_HBA=$(find /etc/postgresql -name "pg_hba.conf" 2>/dev/null | head -n 1)
if [[ -z "$PG_HBA" ]]; then
  echo "⚠️ pg_hba.conf not found, creating new..."
  PG_HBA="/etc/postgresql/${PG_VERSION}/main/pg_hba.conf"
  mkdir -p "$(dirname "$PG_HBA")"
  touch "$PG_HBA"
fi

# Update pg_hba.conf to allow connections:
#   1. For any client connecting as postgres (for admin tasks) over IPv6.
#   2. For replication connections using replicator from any IPv6 address.
#   3. For connections from the primary's public IPv6 for all users.
if ! grep -q "^host\s\+all\s\+postgres\s\+::/0" "$PG_HBA"; then
  echo "host    all             postgres        ::/0         md5" >> "$PG_HBA"
fi

if ! grep -q "^host\s\+replication\s\+${REPL_USER}\s\+::/0" "$PG_HBA"; then
  echo "host    replication     ${REPL_USER}    ::/0         md5" >> "$PG_HBA"
fi

if ! grep -q "${IPV6_ADDR}/128" "$PG_HBA"; then
  echo "host    all             all             ${IPV6_ADDR}/128         md5" >> "$PG_HBA"
fi

# Create WAL archive directory if it doesn't exist
echo "📁 Creating WAL archive directory..."
mkdir -p "${WAL_ARCHIVE_DIR}"
chown -R postgres:postgres "${WAL_ARCHIVE_DIR}"
chmod 700 "${WAL_ARCHIVE_DIR}"

# Restart PostgreSQL to apply changes
echo "🔄 Restarting PostgreSQL..."
systemctl restart postgresql
sleep 5

# Prompt for the postgres superuser password and set it
echo "🔐 Setting password for 'postgres' user."
read -s -p "Enter password for postgres user: " POSTGRES_PASSWORD
echo
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';"

# Create or update replication role
echo "🔐 Creating or updating replication role..."
if sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${REPL_USER}'" | grep -q 1; then
  sudo -u postgres psql -c "ALTER ROLE ${REPL_USER} WITH ENCRYPTED PASSWORD '${REPL_PASSWORD}';"
else
  sudo -u postgres psql -c "CREATE ROLE ${REPL_USER} WITH REPLICATION LOGIN ENCRYPTED PASSWORD '${REPL_PASSWORD}';"
fi

# Create the auth database if it doesn't exist
if ! sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${AUTH_DB}'" | grep -q 1; then
  echo "🆕 Creating database '${AUTH_DB}'..."
  sudo -u postgres createdb "${AUTH_DB}"
fi

# Open the firewall on port 5432 if UFW is installed
if command -v ufw &> /dev/null; then
  echo "🌐 Allowing port 5432 on UFW..."
  ufw allow 5432/tcp
fi

echo "✅ Primary PostgreSQL setup complete using public IPv6 (${IPV6_ADDR})."
echo "You can now connect to the 'auth' database using:"
echo "psql -U postgres -h ${IPV6_ADDR} -d ${AUTH_DB}"
