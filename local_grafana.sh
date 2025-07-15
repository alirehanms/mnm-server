#!/bin/bash

set -e

CONTAINER_NAME="grafana"
VOLUME_NAME="grafana-data"
HOST_PORT=9000
CONTAINER_PORT=3000

# Function to check if Podman is installed
ensure_podman_installed() {
    if ! command -v podman &> /dev/null; then
        echo "Podman is not installed. Installing Podman..."
        sudo apt update
        sudo apt install -y podman
    else
        echo "Podman is already installed."
    fi
}

# Ensure Podman is installed
ensure_podman_installed

# Create volume if it doesn't exist
if ! podman volume exists "$VOLUME_NAME"; then
    echo "Creating volume: $VOLUME_NAME"
    podman volume create "$VOLUME_NAME"
else
    echo "Volume '$VOLUME_NAME' already exists."
fi

# Stop and remove existing container if exists
if podman container exists "$CONTAINER_NAME"; then
    echo "Removing existing container: $CONTAINER_NAME"
    podman stop "$CONTAINER_NAME"
    podman rm "$CONTAINER_NAME"
fi

# Pull Grafana image
echo "Pulling Grafana image..."
podman pull grafana/grafana-oss

# Run Grafana container
echo "Starting Grafana container..."
podman run -d \
    --name "$CONTAINER_NAME" \
    -p "$HOST_PORT:$CONTAINER_PORT" \
    -v "$VOLUME_NAME:/var/lib/grafana" \
    grafana/grafana-oss

echo ""
echo "✅ Grafana is running!"
echo "👉 Access it at: http://localhost:$HOST_PORT"
