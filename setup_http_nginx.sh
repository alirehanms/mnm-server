#!/bin/bash

# Variables
DOMAIN="$1"
APP_NAME="$2"
APP_PORT="$3"
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
NGINX_CONF_FILE="${NGINX_CONF_DIR}/${DOMAIN}.conf"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No color

# Functions
function print_success {
    echo -e "${GREEN}[✔] $1${NC}"
}

function print_error {
    echo -e "${RED}[✘] $1${NC}"
    exit 1
}

function check_command {
    if ! command -v "$1" &>/dev/null; then
        print_error "$1 is not installed. Please install it first."
    fi
}

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
fi

# Validate input
if [ -z "$DOMAIN" ] || [ -z "$APP_PORT" ]; then
    print_error "Usage: $0 <domain> <app_port>"
fi

# Ensure NGINX is installed
check_command nginx

# Create NGINX configuration
echo "Creating NGINX configuration for domain: $DOMAIN..."
cat > "$NGINX_CONF_FILE" <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    location /$APP_NAME {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Enable the configuration
ln -sf "$NGINX_CONF_FILE" "${NGINX_ENABLED_DIR}/$DOMAIN.conf" || print_error "Failed to enable NGINX configuration."

# Test NGINX configuration
nginx -t || print_error "NGINX configuration test failed."

# Reload NGINX
echo "Reloading NGINX..."
nginx -s reload || print_error "Failed to reload NGINX."
print_success "NGINX configuration for $DOMAIN has been added and reloaded."

# Success message
print_success "Setup completed! Your app is now accessible at http://$DOMAIN/$APP_NAME"
