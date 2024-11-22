    if [ $# -lt 1 ]; then
        echo "APP_NAME is required"
        exit 1
    fi
rm out.txt
# Get the arguments
APP_NAME="$1"

echo "CREATE DATABASE IF NOT EXISTS ${APP_NAME};" >> out.txt
random_string=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 41) >/dev/null2 >&1
echo "DROP USER IF EXISTS ${APP_NAME}_def@localhost;" >>out.txt
echo "DROP USER IF EXISTS ${APP_NAME}@localhost;" >>out.txt
echo "CREATE USER  ${APP_NAME}_def@localhost IDENTIFIED WITH caching_sha2_password  BY '$random_string';" >>out.txt
echo "REVOKE ALL PRIVILEGES ON *.* FROM ${APP_NAME}_def@localhost;" >>out.txt
echo "GRANT SELECT,INSERT,UPDATE,DELETE,EXECUTE,CREATE TEMPORARY TABLES on ${APP_NAME}.* TO ${APP_NAME}_def@localhost;" >>out.txt
random_string=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 41) >/dev/null2 >&1
echo "CREATE USER ${APP_NAME}@localhost IDENTIFIED WITH caching_sha2_password BY '$random_string';" >>out.txt
echo "REVOKE ALL PRIVILEGES ON *.* FROM ${APP_NAME}@localhost;" >>out.txt
echo "GRANT EXECUTE on ${APP_NAME}.* TO ${APP_NAME}@localhost;" >>out.txt
echo "FLUSH PRIVILEGES;" >>out.txt
mysql <out.txt
#rm out.txt

