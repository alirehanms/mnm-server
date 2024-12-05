#!/bin/bash

# Variables    # Application name
DOMAIN="$1"      # Domain name
APP_PATH="$2"    # Path to Angular app's dist folder
CERT_PATH="$3"   # Path to SSL certificate directory (must contain fullchain.pem and privkey.pem)
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
if  [ -z "$DOMAIN" ] || [ -z "$APP_PATH" ] || [ -z "$CERT_PATH" ]; then
    print_error "Usage: $0  <domain> <app_path> <cert_path>"
fi

# Ensure NGINX is installed
check_command nginx

# Ensure the app's dist folder exists
if [ ! -d "$APP_PATH" ]; then
    print_error "Application path does not exist: $APP_PATH"
fi

# Ensure the certificate files exist
if [ ! -f "$CERT_PATH/fullchain.pem" ] || [ ! -f "$CERT_PATH/privkey.pem" ]; then
    print_error "Certificate files not found in $CERT_PATH. Ensure fullchain.pem and privkey.pem exist."
fi

# Create NGINX configuration
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

    ssl_certificate ${CERT_PATH}/fullchain.pem;
    ssl_certificate_key ${CERT_PATH}/privkey.pem;

    root $APP_PATH;
    index index.html;

    # Allow .htaccess override (only works if NGINX is compiled with `ngx_http_rewrite_module`)
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    error_page 404 /index.html;

    # Enable .htaccess if allowed
    location ~ /\.ht {
        allow all;
    }

    # Caching headers
    location ~* \.(?:ico|css|js|gif|jpe?g|png|svg|woff2?|eot|ttf|otf|webp)$ {
        expires 6M;
        access_log off;
        add_header Cache-Control "public";
    }

    # Gzip compression
    gzip on;
    gzip_types text/plain application/xml text/css application/javascript;
}
EOL

# Enable the configuration
ln -sf "$NGINX_CONF_FILE" "${NGINX_ENABLED_DIR}/${DOMAIN}.conf" || print_error "Failed to enable NGINX configuration."

# Test NGINX configuration
nginx -t || print_error "NGINX configuration test failed."

# Reload NGINX
echo "Reloading NGINX..."
nginx -s reload || print_error "Failed to reload NGINX."
print_success "NGINX configuration for $DOMAIN has been added and reloaded."

# Success message
print_success "Setup completed! Your app is now accessible at https://$DOMAIN"
