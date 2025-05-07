#!/bin/bash

# PostgreSQL Version
export PG_VERSION=15

# Data Directory
export PGDATA="/var/lib/postgresql/${PG_VERSION}/main"

# Replication Settings
export REPL_USER="replicator"
export REPL_PASSWORD="replicator_pass"
export ARCHIVE_DIR="/var/lib/postgresql/wal_archive"

# Host Addresses (IPv6)
export PRIMARY_HOST="[2a01:4f8:c2c:6a01::1]"  #Test Server
export STANDBY_HOST="[2a01:4f9:c013:1e4::1]" #UID Server
export READONLY_HOST="[2a01:4f8:1c1c:a9c3::1]" #MnM Server

