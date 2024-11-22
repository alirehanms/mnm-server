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


echo "DELETE FROM mysql.user WHERE User='';" >out.txt
echo "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" >>out.txt
echo "DROP DATABASE IF EXISTS test;" >>out.txt
echo "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';" >>out.txt
echo "FLUSH PRIVILEGES;" >>out.txt



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
ssh-add /root/.ssh/id_ed25519



# ssh-keygen -t ed25519 -C "your_email@example.com"
mkdir /srv/MnM
mkdir /srv/cnfg
mkdir /srv/3uLogging
mkdir /srv/ip2location
mkdir /srv/replaylogs

mkdir /srv/3uLogging/exec
mkdir /srv/3uLogging/repo
mkdir /srv/3uLogging/conf
mkdir /srv/3uLogging/rbck


cd /srv/api/
GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone git@github.com:advcomm/3u-engine.git #read-access only to repo
cd 3u-engine

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
echo "ALTER USER 'app'@'localhost' IDENTIFIED BY '$random_string';" >out.txt
mysql <out.txt
rm out.txt
nodejs /var/api/3u-engine/dist/index.js $random_string
set -o history

pm2 start bashscript.sh --name '3u' --interpreter bash



