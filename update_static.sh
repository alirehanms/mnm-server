#!/bin/bash

# Check arguments
if [ $# -lt 3 ]; then
    echo "Usage: $0 <BACKUP_DIR> <REPO_PATH> <SSH_PATH>"
    exit 1
fi

# Get the arguments
BACKUP_DIR="$1"
REPO_PATH="$2"
SSH_PATH="$3"
BRANCH="main"
EXEC_DIR="$(dirname "$(dirname "$REPO_PATH")")/prod"  # Two levels up from REPO_PATH

BACKUP_FILE="$BACKUP_DIR/backup_exec_$(date +%s%3N).zip"

# Ensure BACKUP_DIR exists
mkdir -p "$BACKUP_DIR"

# Navigate to the repository
cd "$REPO_PATH" || { echo "Repository path not found: $REPO_PATH"; exit 1; }

# Fetch updates from the remote repository
echo "Fetching updates from remote..."
GIT_SSH_COMMAND="ssh -i ${SSH_PATH} -o StrictHostKeyChecking=no"  git fetch origin

# Check for changes
echo "Checking for changes..."
CHANGES=$(GIT_SSH_COMMAND="ssh -i ${SSH_PATH} -o StrictHostKeyChecking=no"  git diff --name-only "origin/$BRANCH")

# If no changes are detected, exit
if [[ -z "$CHANGES" ]]; then
    echo "No changes detected. Repository is up-to-date."
    exit 0
fi

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


# Reset to the latest version
echo "Updating repository to the latest version..."
GIT_SSH_COMMAND="ssh -i ${SSH_PATH} -o StrictHostKeyChecking=no"  git reset --hard "origin/$BRANCH"
if [[ $? -ne 0 ]]; then
    echo "Failed to update repository."
    exit 1
fi
echo "Repository updated successfully."

# Replace production folder with required files
echo "Replacing production folder contents with files from repository..."
rm -rf "$EXEC_DIR"/* || { echo "Failed to clean production folder."; exit 1; }
mkdir -p "$EXEC_DIR" || { echo "Failed to recreate production folder."; exit 1; }
cp -r "$REPO_PATH/dist" "$EXEC_DIR/" || { echo "Failed to copy dist folder."; exit 1; }
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