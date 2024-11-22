#!/bin/bash
if [ $# -lt 3 ]; then
    echo "Usage: $0 <BACKUP_DIR> <REPO_PATH> <BRANCH>"
    exit 1
fi

# Get the arguments
BACKUP_DIR="$1"
REPO_PATH="$2"
BRANCH="$3"
BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d%H%M%S).zip"

# Ensure BACKUP_DIR exists
mkdir -p "$BACKUP_DIR"

# Navigate to the repository
cd "$REPO_PATH" || { echo "Repository path not found: $REPO_PATH"; exit 1; }

# Fetch updates from the remote repository
echo "Fetching updates from remote..."
git fetch origin

# Check for changes
echo "Checking for changes..."
CHANGES=$(git diff --name-only "origin/$BRANCH")

# If no changes are detected, exit
if [[ -z "$CHANGES" ]]; then
    echo "No changes detected. Repository is up-to-date."
    exit 0
fi

# If changes are detected, display them
echo "Changes detected:"
echo "$CHANGES"

# Back up the current repository folder only if changes are detected
echo "Backing up current repository..."
zip -r "$BACKUP_FILE" . > /dev/null
if [[ $? -eq 0 ]]; then
    echo "Backup created successfully: $BACKUP_FILE"
else
    echo "Failed to create backup."
    exit 1
fi

# Reset to the latest version
echo "Updating repository to the latest version..."
git reset --hard "origin/$BRANCH"
if [[ $? -eq 0 ]]; then
    echo "Repository updated successfully."
else
    echo "Failed to update repository."
    exit 1
fi
