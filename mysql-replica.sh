# Replica Server Configuration
# 1.	Edit MySQL Configuration:
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
sed '/max_connections /c\max_connections = 101' /etc/mysql/mysql.conf.d/mysqld.cnf

grep -q "max_connections" /etc/mysql/mysql.conf.d/mysqld.cnf && sed -i 's/.*/max_connections = 98/' /etc/mysql/mysql.conf.d/mysqld.cnf || echo "max_connections = 98" >> /etc/mysql/mysql.conf.d/mysqld.cnf

# 2.	Modify the following Lines:
server-id		= 2
log_bin		= /var/log/mysql/mysql-bin.log
binlog_do_db	= 3u_gg3
# 3.	Restart MySQL:
 sudo systemctl restart mysql
# 4.	Configure Slave: Log into the MySQL shell.
mysql -u root -p
# Then run:
CHANGE REPLICATION SOURCE TO
SOURCE_HOST='95.217.129.191',
SOURCE_USER='replica_3ugg',
SOURCE_PASSWORD='P@ssw0rd',
SOURCE_LOG_FILE='mysql-bin.000101',
SOURCE_LOG_POS=157;
# Starting Replication
# To start the Replica run this in MySQL:
START REPLICA;
# Verifying Replication
# To check the status of the replication on the replica server:
	SHOW REPLICA STATUS\G

