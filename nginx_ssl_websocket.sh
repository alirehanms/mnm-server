#!/bin/bash

# Variables
DOMAIN="$1"
APP_NAME="$2"
APP_PORT="$3"
SSL_CERT_PATH="$4"   # Path to the SSL certificate (passed as an argument)
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
if [ -z "$DOMAIN" ] || [ -z "$APP_PORT" ] ; then
    print_error "Usage: $0 <domain> <app_name> <app_port>"
fi

# Ensure NGINX is installed
check_command nginx

# Determine the base domain
if [[ $(echo "$DOMAIN" | grep -o '\.' | wc -l) -eq 1 ]]; then
    BASE_DOMAIN="$DOMAIN"
else
    BASE_DOMAIN=$(echo "$DOMAIN" | sed 's/^[^.]*\.//')
fi

# Check if the SSL certificate directory exists for the base domain
if [ ! -d "/etc/letsencrypt/live/$BASE_DOMAIN" ]; then
    print_error "SSL certificate directory not found for $BASE_DOMAIN. Please ensure the certificate exists at /etc/letsencrypt/live/$BASE_DOMAIN."
fi

# Create NGINX configuration for SSL reverse proxy
echo "Creating NGINX configuration for domain: $DOMAIN..."

cat > "$NGINX_CONF_FILE" <<EOL
server {
    listen 80;
    server_name $DOMAIN;

    # Redirect HTTP to HTTPS
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$BASE_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$BASE_DOMAIN/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$BASE_DOMAIN/chain.pem;

    # SSL settings (optional but recommended)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-AES128-GCM-SHA256:...';
    ssl_prefer_server_ciphers off;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_cache_bypass \$http_upgrade;

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
print_success "Setup completed! Your app is now accessible at https://$DOMAIN"
