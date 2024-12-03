#!/bin/bash

# Variables
DOMAIN="$1"
APP_PORT="$2"
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

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
fi

# Validate input
if [ -z "$DOMAIN" ] || [ -z "$APP_PORT" ]; then
    print_error "Usage: $0 <domain> <app_port>"
fi

# Create NGINX configuration
echo "Creating NGINX configuration for domain: $DOMAIN..."
cat > "$NGINX_CONF_FILE" <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    location / {
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

# Install Certbot if not installed
if ! command -v certbot &>/dev/null; then
    echo "Installing Certbot..."
    apt update && apt install -y certbot python3-certbot-nginx || print_error "Failed to install Certbot."
fi

# Check if a wildcard SSL certificate already exists for the domain
if certbot certificates | grep -q "$DOMAIN"; then
    print_success "Wildcard SSL certificate already exists for $DOMAIN."
else
    # Obtain a wildcard SSL certificate if not already available
    echo "Obtaining wildcard SSL certificate for $DOMAIN..."
    certbot --nginx -d "*.$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN" || print_error "Failed to obtain wildcard SSL certificate."
    print_success "Wildcard SSL certificate obtained for $DOMAIN."
fi

# Reload NGINX after SSL configuration
echo "Reloading NGINX after SSL setup..."
nginx -s reload || print_error "Failed to reload NGINX after SSL setup."
print_success "SSL certificate has been installed and NGINX has been reloaded."

# Success message
print_success "Setup completed! Your app is now accessible at https://$DOMAIN"
