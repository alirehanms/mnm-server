# Use an official Ubuntu base image
FROM ubuntu:20.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    git \
    openssh-client \
    nginx \
    curl \
    software-properties-common \
    && apt-get clean

# Copy the provisioning scripts into the container
COPY . /provisioning

# Copy external scripts into the container
COPY ../../create_postgres_user.sh /srv/scripts/create_postgres_user.sh
COPY ../../update_fetch_pm2.sh /srv/scripts/update_fetch_pm2.sh
COPY ../../nginx_porxy_ip.sh /srv/scripts/nginx_porxy_ip.sh

# Make the scripts executable
RUN chmod +x /provisioning/provision.sh /provisioning/scripts/*.sh /srv/scripts/*.sh

# Set the working directory
WORKDIR /provisioning

# Run the provisioning script
CMD ["bash", "provision.sh"]