if [ $# -lt 1 ]; then
    echo "APP_NAME is required"
    exit 1
fi

# Get the arguments
APP_NAME="$1"

mysql -e "CREATE DATABASE IF NOT EXISTS ${APP_NAME};"
mysql -e "DROP USER IF EXISTS ${APP_NAME}_def@localhost;"
mysql -e "DROP USER IF EXISTS ${APP_NAME}@localhost;"
mysql -e "CREATE USER ${APP_NAME}_def@localhost IDENTIFIED WITH caching_sha2_password BY '$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 41)';"
mysql -e "REVOKE ALL PRIVILEGES ON *.* FROM ${APP_NAME}_def@localhost;"
mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE, CREATE TEMPORARY TABLES ON ${APP_NAME}.* TO ${APP_NAME}_def@localhost;"
mysql -e "CREATE USER ${APP_NAME}@localhost IDENTIFIED WITH caching_sha2_password BY '$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 41)';"
mysql -e "REVOKE ALL PRIVILEGES ON *.* FROM ${APP_NAME}@localhost;"
mysql -e "GRANT EXECUTE on ${APP_NAME}.* TO ${APP_NAME}@localhost;"
mysql -e "FLUSH PRIVILEGES;"

