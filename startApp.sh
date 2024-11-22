set +o history 
random_string=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32) >/dev/null2 >&1
echo "ALTER USER '3ulogging'@'localhost' IDENTIFIED BY '$random_string';" >out.txt
mysql <out.txt
rm out.txt
nodejs /srv/3uLogging/exec/dist/index.js $random_string
set -o history