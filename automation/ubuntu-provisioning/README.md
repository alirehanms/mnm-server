# Ubuntu Application Provisioning

This project provides a set of scripts to provision an application environment on an Ubuntu server. The scripts automate the setup of necessary directories, SSH key generation, database configuration, NGINX setup, and application deployment.

## Project Structure

- **scripts/**: Contains all the scripts used for provisioning.
  - **setup_directories.sh**: Creates necessary directories for the application environment and clones the application repository.
  - **generate_ssh_keys.sh**: Generates SSH keys for secure access to the application repository.
  - **configure_database.sh**: Connects to the database and ensures necessary access for the application.
  - **configure_nginx.sh**: Sets up NGINX as a reverse proxy for the application.
  - **deploy_application.sh**: Pulls the latest code from the application's repository and deploys it.

- **provision.sh**: The main provisioning script that orchestrates the execution of the other scripts and ensures the latest code is fetched from GitHub.

## Prerequisites

- An Ubuntu server with sudo privileges.
- NGINX installed on the server.
- Access to the application repository.
- SSH private key for accessing the repository.

## Usage

1. Clone the repository to your local machine or server.
2. Navigate to the project directory:
   ```bash
   cd ubuntu-provisioning
   ```
3. Make the provisioning script executable:
   ```bash
   chmod +x provision.sh
   ```
4. Run the provisioning script:
   ```bash
   sudo ./provision.sh
   ```

This will execute all the necessary scripts in the correct order to set up your application environment. Ensure that you have the required permissions and configurations before running the script. The script will also write the SSH private key and clone the application repository during the setup process.
