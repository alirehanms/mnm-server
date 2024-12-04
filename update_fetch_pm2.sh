#!/bin/bash

# Check arguments
if [ $# -lt 4 ]; then
    echo "Usage: $0 <BACKUP_DIR> <REPO_PATH> <SSH_PATH> <PM2_PROCESS_NAME>"
    exit 1
fi

# Get the arguments
BACKUP_DIR="$1"
REPO_PATH="$2"
SSH_PATH="$3"
BRANCH="main"
PM2_PROCESS_NAME="$4"
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

# Back up the exec folder only if changes are detected
if [[ -d "$EXEC_DIR" ]]; then
    echo "Backing up exec folder..."
    zip -r "$BACKUP_FILE" "$EXEC_DIR" > /dev/null
    if [[ $? -eq 0 ]]; then
        echo "Backup created successfully: $BACKUP_FILE"
    else
        echo "Failed to create backup of exec folder."
        exit 1
    fi
else
    echo "Exec folder not found: $EXEC_DIR"
    exit 1
fi

# Check and stop the specified PM2 process
if pm2 list | grep -q "$PM2_PROCESS_NAME"; then
    echo "Stopping PM2 process: $PM2_PROCESS_NAME..."
    pm2 stop "$PM2_PROCESS_NAME" || { echo "Failed to stop PM2 process: $PM2_PROCESS_NAME."; exit 1; }
    echo "PM2 process $PM2_PROCESS_NAME stopped successfully."
else
    echo "PM2 process $PM2_PROCESS_NAME does not exist. It will be started after replacement."
fi

# Reset to the latest version
echo "Updating repository to the latest version..."
GIT_SSH_COMMAND="ssh -i ${SSH_PATH} -o StrictHostKeyChecking=no"  git reset --hard "origin/$BRANCH"
if [[ $? -ne 0 ]]; then
    echo "Failed to update repository."
    exit 1
fi
echo "Repository updated successfully."

# Replace exec folder with required files
echo "Replacing exec folder contents with files from repository..."
rm -rf "$EXEC_DIR"/* || { echo "Failed to clean exec folder."; exit 1; }
mkdir -p "$EXEC_DIR" || { echo "Failed to recreate exec folder."; exit 1; }
cp -r "$REPO_PATH/dist" "$EXEC_DIR/" || { echo "Failed to copy dist folder."; exit 1; }
cp -r "$REPO_PATH/node_modules" "$EXEC_DIR/" || { echo "Failed to copy node_modules folder."; exit 1; }
cp "$REPO_PATH/package.json" "$EXEC_DIR/" || { echo "Failed to copy package.json."; exit 1; }
cp "$REPO_PATH/package-lock.json" "$EXEC_DIR/" || { echo "Failed to copy package-lock.json."; exit 1; }
echo "Exec folder updated successfully."

# Start or restart the PM2 process
if pm2 list | grep -q "$PM2_PROCESS_NAME"; then
    echo "Starting PM2 process: $PM2_PROCESS_NAME..."
    pm2 start "$PM2_PROCESS_NAME" || { echo "Failed to start PM2 process: $PM2_PROCESS_NAME."; exit 1; }
    echo "PM2 process $PM2_PROCESS_NAME started successfully."
else
    echo "Starting new PM2 process: $PM2_PROCESS_NAME with file path /srv/scripts/startapp.sh ${PM2_PROCESS_NAME}..."
    pm2 start "/srv/scripts/startapp.sh ${PM2_PROCESS_NAME}" --name "$PM2_PROCESS_NAME" || { echo "Failed to start new PM2 process."; exit 1; }
    echo "New PM2 process $PM2_PROCESS_NAME started successfully."
fi

echo "Update and replacement process completed successfully!"