sudo apt update
sudo apt install mysql-server -y #TODO: Latest Version to do 8.x
sudo apt upgrade -y
sudo systemctl start mysql.service

sudo apt install nginx -y
sudo ufw allow 22
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'
sudo ufw enable -y
sudo systemctl restart nginx
sudo systemctl start nginx

# For learning purpose.
sudo systemctl reload nginx
sudo systemctl enable nginx


#sudo ufw allow 443
# sudo apt install nginx
# sudo ufw app list
# sudo ufw allow 'Nginx HTTP' 


# mysql -e "DELETE FROM mysql.user WHERE User='';"
# mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
# mysql -e "DROP DATABASE IF EXISTS test;"
# mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
# mysql -e "FLUSH PRIVILEGES;"



sudo apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh
sudo -E bash nodesource_setup.sh
sudo apt-get install -y nodejs
node -v

#sudo pm2 completion install
sudo npm install pm2@latest -g && pm2 update

#Generate key for ssh from github..
echo '-----BEGIN OPENSSH PRIVATE KEY-----' >/root/.ssh/id_ed25519
echo 'b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW'>>/root/.ssh/id_ed25519
echo 'QyNTUxOQAAACDS7qKN8l1GPNnaFnAVsoV8OTv0hlQfbf5FIMQ0g+AlRAAAAJCc+SWHnPkl'>>/root/.ssh/id_ed25519
echo 'hwAAAAtzc2gtZWQyNTUxOQAAACDS7qKN8l1GPNnaFnAVsoV8OTv0hlQfbf5FIMQ0g+AlRA'>>/root/.ssh/id_ed25519
echo 'AAAEA5VzyDH7Gm1mLPJlCIhRcd5N04/lqPZ5EjscTuWGxn5tLuoo3yXUY82doWcBWyhXw5'>>/root/.ssh/id_ed25519
echo 'O/SGVB9t/kUgxDSD4CVEAAAADXJvb3RAM3UtaGVsLTE='>>/root/.ssh/id_ed25519
echo '-----END OPENSSH PRIVATE KEY-----'>>/root/.ssh/id_ed25519
chmod 600 /root/.ssh/id_ed25519

eval "$(ssh-agent -s)"

ssh-add /srv/3ulogging/ssh/3uLoggingDB

#================================= common scripts===============================
# Install Nginx
sudo apt install nginx -y
sudo ufw allow 22
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'
sudo ufw enable -y
sudo systemctl restart nginx
sudo systemctl start nginx

# Node installation..
sudo apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh
sudo -E bash nodesource_setup.sh
sudo apt-get install -y nodejs
node -v

#sudo pm2 completion install
sudo npm install pm2@latest -g && pm2 update

mkdir /srv/scripts

#Install mysql community server..
nano mysql.sh
chmod +x mysql.sh
./mysql.sh 

nano mysql_user.sh
chmod +x mysql_user.sh

nano update_db.sh
chmod +x update_db.sh

nano update_fetch_pm2.sh
chmod +x update_fetch_pm2.sh

nano nginx_proxy_ip.sh
chmod +x nginx_proxy_ip.sh

nano startapp.sh
chmod +x startapp.sh

nano update_static.sh
chmod +x update_static.sh

#================================== apps =======================================
mkdir /srv/MnM
mkdir /srv/cnfg
mkdir /srv/replaylogs

# ========================================== 3ulogging ==========================================
mkdir /srv/3ulogging
mkdir /srv/3ulogging/prod
mkdir /srv/3ulogging/repo
mkdir /srv/3ulogging/conf
mkdir /srv/3ulogging/rbck
mkdir /srv/3ulogging/scripts
mkdir /srv/3ulogging/ssh


ssh-keygen -t ed25519 -C "dev1@hostingcontroller.com" -f /srv/3ulogging/ssh/3ulogging -N ""
ssh-keygen -t ed25519 -C "dev1@hostingcontroller.com" -f /srv/3ulogging/ssh/3uloggingdb -N ""

cd /srv/3ulogging/repo
GIT_SSH_COMMAND="ssh -i /srv/3ulogging/ssh/3uloggingdb -o StrictHostKeyChecking=no" git clone git@github.com:3ugg/3uloggingdb.git
cd /srv/scripts
/srv/scripts/mysql_user.sh 3ulogging
/srv/scripts/update_db.sh  /srv/3ulogging/backup/mysql /srv/3ulogging/repo/3uloggingdb   /srv/3ulogging/ssh/3uloggingdb 3ulogging

cd /srv/3ulogging/repo
GIT_SSH_COMMAND="ssh -i /srv/3ulogging/ssh/3ulogging -o StrictHostKeyChecking=no" git clone git@github.com:3ugg/logging-prod.git

/srv/scripts/update_fetch_pm2.sh /srv/3ulogging/backup /srv/3ulogging/repo/3ulogging-prod /srv/3ulogging/ssh/3ulogging 3ulogging
/srv/scripts/nginx_proxy_ip.sh 37.27.189.44 3ulogging 9502

# ========================================= geolocation ===========================================
mkdir /srv/geolocation
mkdir /srv/geolocation/prod
mkdir /srv/geolocation/repo
mkdir /srv/geolocation/conf
mkdir /srv/geolocation/rbck
mkdir /srv/geolocation/scripts
mkdir /srv/geolocation/ssh

ssh-keygen -t ed25519 -C "dev1@hostingcontroller.com" -f /srv/geolocation/ssh/geolocation -N ""
ssh-keygen -t ed25519 -C "dev1@hostingcontroller.com" -f /srv/geolocation/ssh/geolocationdb -N ""
cd /srv/geolocation/repo
GIT_SSH_COMMAND="ssh -i /srv/geolocation/ssh/geolocationdb -o StrictHostKeyChecking=no" git clone git@github.com:advcomm/geolocationdb.git


cd /srv/scripts
nano mysql_user.sh
chmod +x mysql_user.sh
/srv/scripts/mysql_user.sh geolocation
nano update_db.sh
chmod +x update_db.sh
/srv/scripts/update_db.sh  /srv/geolocation/backup/mysql /srv/geolocation/repo/geolocationdb   /srv/geolocation/ssh/geolocationdb geolocation

cd /srv/geolocation/scripts 
nano import_ipcountry.sh
chmod +x import_ipcountry.sh
/srv/geolocation/scripts/import_ipcountry.sh "U0n6gjf3pM7FDZyyS7vGCqsTcV1ju93okU3ho7q4uoymGWEW3UFjQ7zHF8sfjdXi"  


cd /srv/geolocation/repo
GIT_SSH_COMMAND="ssh -i /srv/geolocation/ssh/geolocation -o StrictHostKeyChecking=no" git clone git@github.com:advcomm/geolocation-prod.git

cd /srv/geolocation/scripts
nano startapp.sh
chmod +x startapp.sh


/srv/scripts/update_fetch_pm2.sh /srv/geolocation/backup /srv/geolocation/repo/geolocation-prod /srv/geolocation/ssh/geolocation geolocation
/srv/scripts/nginx_proxy_ip.sh 37.27.189.44 geolocation 9504

# ========================================= 3uadmin ===========================================
mkdir /srv/3uadmin
mkdir /srv/3uadmin/prod
mkdir /srv/3uadmin/repo
mkdir /srv/3uadmin/conf
mkdir /srv/3uadmin/rbck
mkdir /srv/3uadmin/scripts
mkdir /srv/3uadmin/ssh

ssh-keygen -t ed25519 -C "dev1@hostingcontroller.com" -f /srv/3uadmin/ssh/3uadmin -N ""
ssh-keygen -t ed25519 -C "dev1@hostingcontroller.com" -f /srv/3uadmin/ssh/3uadmindb -N ""

cd /srv/3uadmin/scripts
nano mysql_admin_user.sh
chmod +x mysql_admin_user.sh
/srv/3uadmin/scripts/mysql_admin_user.sh


cd /srv/3uadmin/repo
GIT_SSH_COMMAND="ssh -i /srv/3uadmin/ssh/3uadmindb -o StrictHostKeyChecking=no" git clone git@github.com:3ugg/3uadmindb.git

/srv/scripts/update_db.sh  /srv/3uadmin/backup/mysql /srv/3uadmin/repo/3uadmindb   /srv/3uadmin/ssh/3uadmindb 3uadmin


cd /srv/3uadmin/repo
GIT_SSH_COMMAND="ssh -i /srv/3uadmin/ssh/3uadmin -o StrictHostKeyChecking=no" git clone git@github.com:3ugg/3uadmin-prod.git

cd /srv/3uadmin/conf
nano serverapi.env

/srv/scripts/update_fetch_pm2.sh /srv/3uadmin/backup /srv/3uadmin/repo/3uadmin-prod /srv/3uadmin/ssh/3uadmin 3uadmin

#/srv/scripts/nginx_proxy_ip.sh 37.27.189.44 3uadmin 9504



# ========================================= 3uengine ===========================================
mkdir /srv/3uengine
mkdir /srv/3uengine/prod
mkdir /srv/3uengine/repo
mkdir /srv/3uengine/conf
mkdir /srv/3uengine/rbck
mkdir /srv/3uengine/scripts
mkdir /srv/3uengine/ssh

ssh-keygen -t ed25519 -C "dev1@hostingcontroller.com" -f /srv/3uengine/ssh/3uengine -N ""
/srv/scripts/mysql_user.sh 3uengine

cd /srv/3uengine/repo
GIT_SSH_COMMAND="ssh -i /srv/3uengine/ssh/3uengine -o StrictHostKeyChecking=no" git clone git@github.com:3ugg/3uengine-prod.git

/srv/scripts/update_fetch_pm2.sh /srv/3uengine/backup /srv/3uengine/repo/3uengine-prod /srv/3uengine/ssh/3uengine 3uengine
/srv/scripts/nginx_ssl.sh 3u.gg 9501

# ========================================= 3uadmingui ===========================================
mkdir /srv/3uadmingui
mkdir /srv/3uadmingui/prod
mkdir /srv/3uadmingui/repo
mkdir /srv/3uadmingui/conf
mkdir /srv/3uadmingui/rbck
mkdir /srv/3uadmingui/scripts
mkdir /srv/3uadmingui/ssh

ssh-keygen -t ed25519 -C "dev1@hostingcontroller.com" -f /srv/3uadmingui/ssh/3uadmingui -N ""
/srv/scripts/mysql_user.sh 3uadmingui

cd /srv/3uadmingui/repo
GIT_SSH_COMMAND="ssh -i /srv/3uadmingui/ssh/3uadmingui -o StrictHostKeyChecking=no" git clone git@github.com:3ugg/3uadmingui-prod.git

#/srv/scripts/deploy_angular_nginx.sh my-app myapp.example.com /var/www/my-app/dist /etc/letsencrypt/live/example.com

/srv/scripts/update_static.sh /srv/3uadmingui/backup /srv/3uadmingui/repo/3uadmingui-prod /srv/3uadmingui/ssh/3uadmingui 

# =================================================================================================================
#git fetch origin
#git reset --hard origin/main

# Fetch updates from the remote repository
echo "Fetching updates from remote..."
git fetch origin

# Check for changes
echo "Checking for changes..."
CHANGES=$(git diff --name-only "origin/$BRANCH")

if [[ -z "$CHANGES" ]]; then
    echo "No changes detected. Repository is up-to-date."
    exit 0
fi

echo "Changes detected:"
echo "$CHANGES"

# Back up the current repository folder
echo "Backing up current repository..."
zip -r "$BACKUP_FILE" . > /dev/null
if [[ $? -eq 0 ]]; then
    echo "Backup created successfully: $BACKUP_FILE"
else
    echo "Failed to create backup."
    exit 1
fi










# bashscript.sh
set +o history 
random_string=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32) >/dev/null2 >&1
mysql -e "ALTER USER 'app'@'localhost' IDENTIFIED BY '$random_string';"
nodejs /var/api/3u-engine/dist/index.js $random_string
set -o history

pm2 start bashscript.sh --name '3u' --interpreter bash



