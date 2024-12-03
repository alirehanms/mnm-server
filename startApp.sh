if [ $# -lt 1 ]; then
    echo "Usage: $0  <APP_NAME> "
    exit 1
fi
# Arguments
APP_NAME="$1"

set +o history 
random_string=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 41) >/dev/null2 >&1
mysql -e "ALTER USER ${APP_NAME}@'localhost' IDENTIFIED BY '$random_string';"
nodejs /srv/${APP_NAME}/prod/dist/index.js $random_string
set -o history
