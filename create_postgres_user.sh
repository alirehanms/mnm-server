if [ $# -lt 1 ]; then
    echo "APP_NAME is required"
    exit 1
fi

# Get the arguments
APP_NAME="$1"

sudo -u postgres psql -c "CREATE DATABASE ${APP_NAME};"
sudo -u postgres psql -c "DO $$ BEGIN IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${APP_NAME}_def') THEN REVOKE ALL PRIVILEGES ON DATABASE ${APP_NAME} FROM ${APP_NAME}_def; DROP ROLE ${APP_NAME}_def; END IF; END $$;"
sudo -u postgres psql -c "DO $$ BEGIN IF EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${APP_NAME}') THEN REVOKE ALL PRIVILEGES ON DATABASE ${APP_NAME} FROM ${APP_NAME}; DROP ROLE ${APP_NAME}; END IF; END $$;"
sudo -u postgres psql -c "CREATE ROLE ${APP_NAME}_def WITH LOGIN;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${APP_NAME} TO ${APP_NAME}_def;"
sudo -u postgres psql -c "CREATE ROLE ${APP_NAME} WITH LOGIN;"
sudo -u postgres psql -c "GRANT CONNECT ON DATABASE ${APP_NAME} TO ${APP_NAME};"
sudo -u postgres psql -c "GRANT USAGE ON SCHEMA public TO ${APP_NAME};"
sudo -u postgres psql -c "GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ${APP_NAME};"