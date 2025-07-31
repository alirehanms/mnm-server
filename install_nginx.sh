sudo apt update
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