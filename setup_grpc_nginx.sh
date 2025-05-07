#!/bin/bash

set -e

# === Config ===
SERVICE_NAME="$1"
CONF_DIR="./nginx/conf.d"
CONF_PATH="${CONF_DIR}/${SERVICE_NAME}.conf"
SOCKET_PATH="/tmp/grpc/${SERVICE_NAME}.sock"
CONTAINER_NAME="nginx"
IMAGE_NAME="docker.io/library/nginx:latest"
HOST_PORT=80

# === Validation ===
if [ -z "$SERVICE_NAME" ]; then
  echo "Usage: $0 <service_name>"
  exit 1
fi

# === Prepare Config ===
mkdir -p "$CONF_DIR"

echo "Creating NGINX config for '$SERVICE_NAME'..."

cat > "$CONF_PATH" <<EOF
server {
      listern 80;
      listen [::]:80;
     http2 on;
    server_name localhost;

    location / {
        grpc_pass grpc://unix:$SOCKET_PATH;
        error_page 502 = /error502grpc;
    }

    location = /error502grpc {
        internal;
        default_type application/grpc;
        add_header grpc-status 14;
        add_header grpc-message "unavailable";
        return 204;
    }
}
EOF

echo "✅ Config written to $CONF_PATH"

# === Ensure NGINX Container is Running ===
if ! podman container exists "$CONTAINER_NAME"; then
  echo "NGINX container '$CONTAINER_NAME' does not exist. Creating and starting it..."
  podman run -d \
    --name "$CONTAINER_NAME" \
    -p $HOST_PORT:80 \
    -v "/nginx/conf.d:/etc/nginx/conf.d:Z" \
    -v /srv/grpc:/tmp/grpc:Z \
    "$IMAGE_NAME"
else
  STATUS=$(podman inspect -f '{{.State.Status}}' "$CONTAINER_NAME")
  if [ "$STATUS" != "running" ]; then
    echo "Starting existing container '$CONTAINER_NAME'..."
    podman start "$CONTAINER_NAME"
  else
    echo "Reloading NGINX inside running container..."
    podman exec "$CONTAINER_NAME" nginx -t && podman exec "$CONTAINER_NAME" nginx -s reload
  fi
fi

echo "✅ NGINX is proxying gRPC service '$SERVICE_NAME' via Unix socket at /$SERVICE_NAME"
