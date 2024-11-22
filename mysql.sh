#!/bin/bash

# Exit on any error
set -e

# Variables
 # Update version as needed

MYSQL_DEB_URL="https://dev.mysql.com/get/mysql-apt-config_0.8.33-1_all.deb"
MYSQL_DEB_PACKAGE="mysql-apt-config_8.33-1_all.deb"

echo "Starting MySQL installation script..."

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Use sudo."
  exit 1
fi



# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y wget lsb-release gnupg

# Download MySQL APT configuration package
if [ ! -f "$MYSQL_DEB_PACKAGE" ]; then
  echo "Downloading MySQL APT config package..."
  wget "$MYSQL_DEB_URL" -O "$MYSQL_DEB_PACKAGE"
else
  echo "MySQL APT config package already downloaded."
fi

# Install the MySQL APT repository
echo "Configuring MySQL APT repository..."
dpkg -i "$MYSQL_DEB_PACKAGE" -y

# Update package information
echo "Updating package list..."
apt-get update

# Install MySQL Server
echo "Installing MySQL Server..."
DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

# Start MySQL Service
echo "Starting MySQL service..."
systemctl start mysql
systemctl enable mysql

# Secure Installation (Optional - Modify for your setup)
echo "Securing MySQL installation..."
mysql_secure_installation <<EOF

Y
root_password
root_password
Y
Y
Y
Y
EOF

# Verify Installation
echo "Verifying MySQL installation..."
mysql --version

echo "MySQL installation completed successfully!"
