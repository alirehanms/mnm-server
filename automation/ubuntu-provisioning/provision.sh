#!/bin/bash

# Provisioning script to set up the application environment

# Step 1: Create necessary directories and clone the repository
bash scripts/setup_directories.sh

# Step 2: Configure the database
bash scripts/configure_database.sh

# Step 3: Configure NGINX as a reverse proxy
bash scripts/configure_nginx.sh

# Step 4: Deploy the application
bash scripts/deploy_application.sh

# Step 5: Update and fetch the latest code from GitHub
#bash scripts/update_fetch_pm2.sh

echo "Provisioning completed successfully."