#!/bin/bash

# Deploy the application
APP_NAME=${APP_NAME:-default_app}
REPO_DIR="/srv/$APP_NAME/repo"
SSH_KEY="/srv/$APP_NAME/ssh/$APP_NAME"

#GIT_SSH_COMMAND="ssh -i $SSH_KEY -o StrictHostKeyChecking=no" git clone git@github.com:your-org/$APP_NAME-prod.git $REPO_DIR

/srv/scripts/update_fetch_pm2.sh /srv/$APP_NAME/backup $REPO_DIR/$APP_NAME-prod $SSH_KEY $APP_NAME

echo "Application deployed successfully."