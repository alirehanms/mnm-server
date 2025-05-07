#!/bin/bash

# Configure the database for the application
APP_NAME=${APP_NAME:-default_app}

/srv/scripts/create_postgres_user.sh $APP_NAME

echo "Database configured successfully."