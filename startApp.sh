set +o history 
random_string=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 41) >/dev/null2 >&1
mysql -e "ALTER USER '3ulogging'@'localhost' IDENTIFIED BY '$random_string';"
nodejs /srv/3uLogging/prod/dist/index.js $random_string
set -o history
