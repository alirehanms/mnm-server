sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -i -u postgres
psql
ALTER USER postgres WITH PASSWORD 'P@ssw0rd';

