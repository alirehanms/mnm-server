#!/bin/bash

# Update system package list
echo "Updating package list..."
sudo apt update

# Install Redis
echo "Installing Redis..."
sudo apt install -y redis-server

# Configure Redis to start on boot
echo "Enabling Redis to start on boot..."
sudo systemctl enable redis-server

# Start Redis service
echo "Starting Redis service..."
sudo systemctl start redis-server

# Check Redis status
echo "Checking Redis status..."
sudo systemctl status redis-server | grep "active (running)"

# Test Redis installation
echo "Testing Redis installation..."
redis-cli ping

if [ $? -eq 0 ]; then
    echo "Redis is installed and running successfully!"
else
    echo "Redis installation failed or service is not running."
fi

# Optional: Secure Redis installation
echo "Securing Redis (optional, requires password setup)..."
# Uncomment below to require Redis password (only if needed)
# sudo sed -i 's/# requirepass foobared/requirepass YOURPASSWORD/' /etc/redis/redis.conf
# sudo systemctl restart redis-server

echo "Redis installation script completed."
