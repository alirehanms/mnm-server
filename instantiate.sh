#!/bin/bash
# Function to print usage and exit
function print_usage_and_exit {
    echo "Usage: $0 --username <username> --userprivilege <privilege> [--createMySql] [--installNode] [--createUser]"
    exit 1
}

# Function to check if MySQL is installed
function check_mysql {
    if ! command -v mysql &>/dev/null; then
        echo "MySQL is not installed. Installing..."
       /srv/scripts/mysql.sh
        echo "MySQL installed successfully."
    else
        echo "MySQL is already installed."
    fi
}

# Function to install Node.js
function install_node {
    if ! command -v node &>/dev/null; then
        echo "Node.js is not installed. Installing..."
       sudo apt-get install -y curl
        curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh
        sudo -E bash nodesource_setup.sh
        sudo apt-get install -y nodejs
        node -v
        echo "Node.js installed successfully."
    else
        echo "Node.js is already installed."
    fi
}

# Function to create a user
function create_user {
    local username=$1
    local userprivilege=$2
    local user_home="/srv/$username"
    local GROUPNAME="apps"

    # Check if user exists
    if id "$username" &>/dev/null; then
        echo "User $username already exists."
        return
    fi

    # Check if /srv/{username} exists
    if [ -d "/home/$username" ] || [ -d "$user_home" ]; then
        error_exit "User's home directory or /srv/${username} already exists."
    fi

    # Create group if it doesn't exist
    if ! getent group apps &>/dev/null; then
        sudo groupadd apps
        echo "Group 'apps' created."
    fi

    echo "Creating user '$username' with no password and nologin shell..."
    useradd -s /usr/sbin/nologin -G "$GROUPNAME" "$username"
    sudo chmod "$userprivilege" "/home/$username"

    # Create the /srv/{user} directory
    echo "Creating directory $user_home..."
    mkdir -p "$user_home"

    # Set ownership to the new user
    #chown "$username:$GROUPNAME" "$user_home"
    echo "User $username created with home directory /home/$username and privileges $userprivilege."
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --username)
            username="$2"
            shift
            ;;
        --userprivilege)
            userprivilege="$2"
            shift
            ;;
        --createMySql)
            createMySql=true
            ;;
        --installNode)
            installNode=true
            ;;
        --createUser)
            createUser=true
            ;;
        *)
            echo "Unknown parameter: $1"
            print_usage_and_exit
            ;;
    esac
    shift
done

# Validate mandatory parameters
if [[ -z "$username" || -z "$userprivilege" ]]; then
    echo "Error: --username and --userprivilege are mandatory."
    print_usage_and_exit
fi

# Execute optional tasks
if [[ "$createMySql" == "true" ]]; then
    check_mysql
fi

if [[ "$installNode" == "true" ]]; then
    install_node
fi

if [[ "$createUser" == "true" ]]; then
    create_user "$username" "$userprivilege"
fi

echo "Script execution completed."

