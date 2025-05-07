#!/bin/bash

if [ $# -lt 4 ]; then
    echo "Usage: $0 <BACKUP_DIR> <REPO_PATH> <SSH_PATH> <APP_NAME> "
    exit 1
fi

# Arguments
BACKUP_DIR="$1"
REPO_PATH="$2"
DB_NAME="$4"
DB_USER="${4}_def"   
BRANCH="main"
SSH_PATH="$3"
DB_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 41)       # Default to an empty password if not provided
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$(date +%s%3N).sql"
LOG_FILE="$BACKUP_DIR/${DB_NAME}_update_log_$(date +%s%3N).log"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Navigate to the repository
cd "$REPO_PATH" || { echo "Repository path not found: $REPO_PATH"; exit 1; }

# Fetch updates from the remote repository
echo "Fetching updates from remote repository..."
GIT_SSH_COMMAND="ssh -i ${SSH_PATH} -o StrictHostKeyChecking=no" git fetch origin

# Check for changes
echo "Checking for changes in branch origin..."
CHANGES=$(GIT_SSH_COMMAND="ssh -i ${SSH_PATH} -o StrictHostKeyChecking=no" git diff --name-only "origin/$BRANCH")

# If no changes are detected, exit
if [[ -z "$CHANGES" ]]; then
    echo "No changes detected. Repository is up-to-date."
    exit 0
fi

# If changes are detected, pull the latest changes
echo "Changes detected. Pulling latest updates..."
GIT_SSH_COMMAND="ssh -i ${SSH_PATH} -o StrictHostKeyChecking=no" git reset --hard "origin/$BRANCH" || { echo "Failed to pull updates from branch $BRANCH."; exit 1; }
echo "Repository updated successfully."

# Identify changed SQL files
echo "Filtering changed SQL files..."mysq
CHANGED_SQL_FILES=$(echo "$CHANGES" | grep '\.sql$' | sort)
# If no changed SQL files are found, exit
if [[ -z "$CHANGED_SQL_FILES" ]]; then
    echo "No SQL files have changed. No updates required."
    exit 0
fi

#mysql -e "ALTER USER ${DB_USER}@localhost IDENTIFIED BY '${DB_PASSWORD}';"
#Backup schema..
echo "Creating backup of database $DB_NAME..."
mysqldump -u "$DB_USER" -p"$DB_PASSWORD" --no-data --single-transaction "$DB_NAME" > "$BACKUP_FILE" 2>>"$LOG_FILE"
if [ $? -ne 0 ]; then
    echo "Backup failed. Check log file: $LOG_FILE"
    exit 1
fi
echo "Backup created successfully: $BACKUP_FILE"

# Apply changed SQL files in alphabetical order
echo "Applying changed SQL files..."
for REL_SQL_FILE in $CHANGED_SQL_FILES; do
    SQL_FILE="$REPO_PATH/$REL_SQL_FILE"
    echo "Processing $SQL_FILE..."
    mysql -e "SET GLOBAL log_bin_trust_function_creators = 1;"
    mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$SQL_FILE" 2>>"$LOG_FILE"
    if [ $? -ne 0 ]; then
        echo "Error applying $SQL_FILE. Check log file: $LOG_FILE"
        echo "Rolling back to backup..."
        mysql -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$BACKUP_FILE" 2>>"$LOG_FILE"
        if [ $? -eq 0 ]; then
            echo "Rollback successful."
        else
            echo "Rollback failed. Manual intervention required."
        fi
        exit 1
    else
        echo "Successfully applied $SQL_FILE"
    fi
done

echo "All changed SQL files applied successfully. Check log file: $LOG_FILE"
