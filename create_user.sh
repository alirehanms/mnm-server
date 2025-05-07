#!/bin/bash

# Exit on any error
set -e

# Function to print error message and exit
function error_exit {
    echo "Error: $1"
    exit 1
}

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    error_exit "This script must be run as root."
fi

# Variables
USERNAME=$1
GROUPNAME="apps"
USER_HOME_DIR="/srv/${USERNAME}"

# Check if username is provided
if [ -z "$USERNAME" ]; then
    error_exit "Usage: $0 <username>"
fi

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
    error_exit "User '$USERNAME' already exists."
fi

# Check if group exists, if not create it
if ! getent group "$GROUPNAME" &>/dev/null; then
    echo "Group '$GROUPNAME' does not exist. Creating..."
    groupadd "$GROUPNAME"
fi

# Check if user's data directory exists
if [ -d "/home/$USERNAME" ] || [ -d "$USER_HOME_DIR" ]; then
    error_exit "User's home directory or /srv/${USERNAME} already exists."
fi

# Create the user with disabled password and nologin shell
echo "Creating user '$USERNAME' with no password and nologin shell..."
useradd -M -s /usr/sbin/nologin -G "$GROUPNAME" "$USERNAME"

# Create the /srv/{user} directory
echo "Creating directory $USER_HOME_DIR..."
mkdir -p "$USER_HOME_DIR"

# Set ownership to the new user
chown "$USERNAME:$GROUPNAME" "$USER_HOME_DIR"

# Confirm success
echo "User '$USERNAME' created and added to group '$GROUPNAME'."
echo "Directory '$USER_HOME_DIR' created successfully."
