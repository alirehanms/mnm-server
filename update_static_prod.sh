#!/bin/bash

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <BACKUP_DIR> <REPO_PATH> "
    exit 1
fi

# Get the arguments
BACKUP_DIR="$1"
REPO_PATH="$2"
BRANCH="main"
EXEC_DIR="$(dirname "$(dirname "$REPO_PATH")")/prod"  # Two levels up from REPO_PATH

BACKUP_FILE="$BACKUP_DIR/backup_exec_$(date +%s%3N).zip"

# Ensure BACKUP_DIR exists
mkdir -p "$BACKUP_DIR"

# Navigate to the repository
cd "$REPO_PATH" || { echo "Repository path not found: $REPO_PATH"; exit 1; }

# If changes are detected, display them
echo "Changes detected:"
echo "$CHANGES"

# Back up the production folder only if changes are detected
if [[ -d "$EXEC_DIR" ]]; then
    echo "Backing up production folder..."
    zip -r "$BACKUP_FILE" "$EXEC_DIR" > /dev/null
    if [[ $? -eq 0 ]]; then
        echo "Backup created successfully: $BACKUP_FILE"
    else
        echo "Failed to create backup of production folder."
        exit 1
    fi
else
    echo "Production folder not found: $EXEC_DIR"
    exit 1
fi

# Replace production folder with required files
echo "Replacing production folder contents with files from repository..."
rm -rf "$EXEC_DIR"/* || { echo "Failed to clean production folder."; exit 1; }
mkdir -p "$EXEC_DIR" || { echo "Failed to recreate production folder."; exit 1; }
cp -r "$REPO_PATH/" "$EXEC_DIR/" || { echo "Failed to copy production folder."; exit 1; }
echo "Production folder updated successfully."

echo "Restarting NGINX..."
sudo systemctl restart nginx
if [[ $? -eq 0 ]]; then
    echo "NGINX restarted successfully."
else
    echo "Failed to restart NGINX."
    exit 1
fi

echo "Update and replacement process completed successfully!"