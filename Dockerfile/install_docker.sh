#!/bin/bash

####################################################################################################################
# Author: Moutaz Muhammad <moutazmuhamad@gmail.com>
# Modified to support Ubuntu 16, 20, 22, 24, CentOS, and Red Hat

# curl -s https://raw.githubusercontent.com/moutazmuhammad/odoo-docker-compose/main/Dockerfile/install_docker.sh | sudo bash
####################################################################################################################
set -e

# Detect OS and version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "Cannot determine OS"
    exit 1
fi

# Function to check and install Docker
check_install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not found. Installing Docker..."
        if [ "$OS" == "ubuntu" ]; then
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ]; then
            if [[ "$VER" == 7.* ]]; then
                sudo yum remove -y docker docker-common docker-selinux docker-engine
                sudo yum install -y yum-utils device-mapper-persistent-data lvm2
                sudo yum-config-manager --add-repo https://download.docker.com/linux/$OS/docker-ce.repo
                sudo yum install -y docker-ce
            else
                sudo dnf -y install dnf-plugins-core
                sudo dnf config-manager --add-repo https://download.docker.com/linux/$OS/docker-ce.repo
                sudo dnf install -y docker-ce docker-ce-cli containerd.io
            fi
            sudo systemctl enable docker.service
            sudo systemctl start docker.service
        else
            echo "Unsupported OS: $OS"
            exit 1
        fi

        # Allow current user to run Docker without sudo
        sudo groupadd docker 2>/dev/null || true
        sudo usermod -aG docker "$USER"
        newgrp docker <<EONG
echo "[INFO] Docker installed and user added to docker group."
EONG

    else
        echo "[INFO] Docker is already installed."
    fi
}

# Function to check and install Docker Compose
check_install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "[INFO] Docker Compose not found. Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "[INFO] Docker Compose installed successfully."
    else
        echo "[INFO] Docker Compose is already installed."
    fi
}


