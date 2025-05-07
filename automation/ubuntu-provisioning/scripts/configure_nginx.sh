#!/bin/bash

# Configure NGINX as a reverse proxy for the application
APP_NAME=${APP_NAME:-3u.gg}
DOMAIN=${DOMAIN:-167.235.23.189}
PORT=${PORT:-9501}

/srv/scripts/nginx_proxy_ip.sh $DOMAIN $APP_NAME $PORT

echo "NGINX configured successfully."