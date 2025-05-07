#!/bin/bash

# Create necessary directories for the application
APP_NAME=${APP_NAME:-default_app}
BASE_DIR="/srv/$APP_NAME"

mkdir -p $BASE_DIR/prod
mkdir -p $BASE_DIR/repo
mkdir -p $BASE_DIR/conf
mkdir -p $BASE_DIR/rbck
mkdir -p $BASE_DIR/scripts
mkdir -p $BASE_DIR/ssh

# Write the SSH private key

chmod 600 $BASE_DIR/ssh/$APP_NAME

# Clone the application repository
cd $BASE_DIR/repo
GIT_SSH_COMMAND="ssh -i $BASE_DIR/ssh/$APP_NAME -o StrictHostKeyChecking=no" git clone git@github.com:your-org/$APP_NAME-prod.git

echo "Directories created, SSH key written, and repository cloned successfully."