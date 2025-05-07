#!/bin/bash

# Variables
IP_ADDRESS="$1"  # Use the machine's IP address
APP_NAME="$2"    # Application name
NGINX_CONF_DIR="/etc/nginx/sites-available"
NGINX_ENABLED_DIR="/etc/nginx/sites-enabled"
NGINX_CONF_FILE="${NGINX_CONF_DIR}/reverse-proxy.conf"  # Single file for all apps

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
if [ -z "$IP_ADDRESS" ] || [ -z "$APP_NAME" ];  then
    print_error "Usage: $0 <ip_address> <app_name>"
fi

# Ensure NGINX is installed
check_command nginx

# Create or update the NGINX configuration for the reverse proxy
echo "Updating NGINX configuration for IP: $IP_ADDRESS..."
if [ ! -f "$NGINX_CONF_FILE" ]; then
    # Create the initial server block if it doesn't exist
    cat > "$NGINX_CONF_FILE" <<EOL
server {
    listen 80;
    server_name $IP_ADDRESS;

    # Default fallback for unmatched requests
    location / {
        return 404;
    }
}
EOL
fi

# Check if the app-specific location block already exists
if grep -q "location /$APP_NAME" "$NGINX_CONF_FILE"; then
    print_error "Configuration for $APP_NAME already exists. Use a different name."
else
    # Insert the app-specific location block before the closing "}" of the server block
    sed -i "/^}$/i\    # Proxy for $APP_NAME\n    location /$APP_NAME {\n        rewrite ^/$APP_NAME/(.*)\$ /\$1  break;\n        proxy_pass http://unix:$APP_NAME;\n        proxy_set_header Host \$host;\n        proxy_set_header X-Real-IP \$remote_addr;\n        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n        proxy_set_header X-Forwarded-Proto \$scheme;\n    }\n" "$NGINX_CONF_FILE"
fi

# Enable the configuration
ln -sf "$NGINX_CONF_FILE" "${NGINX_ENABLED_DIR}/reverse-proxy.conf" || print_error "Failed to enable NGINX configuration."

# Test NGINX configuration
nginx -t || print_error "NGINX configuration test failed."

# Reload NGINX
echo "Reloading NGINX..."
nginx -s reload || print_error "Failed to reload NGINX."
print_success "NGINX configuration for $APP_NAME has been added and reloaded."

# Success message
print_success "Setup completed! Your app $APP_NAME is now accessible at http://$IP_ADDRESS/$APP_NAME"
