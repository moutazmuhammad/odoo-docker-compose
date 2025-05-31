#!/bin/bash

##########################################################################################################################################
# Author: Moutaz Muhammad <moutazmuhamad@gmail.com>
# Support Ubuntu 16, 20, 22, 24, CentOS, and Red Hat

# Setup odoo14 & postgresql 14
# curl -s https://raw.githubusercontent.com/moutazmuhammad/odoo-docker-compose/main/Dockerfile/odoo14/scripts/linux_setup_pg14.sh | bash
##########################################################################################################################################
set -e

# Base directory for the project
BASE_DIR="${BASE_DIR:-$PWD/ODOO14_pg14}"
mkdir -p $BASE_DIR
VERSIONS=("14")

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
        sudo chmod 666 /var/run/docker.sock

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


# Function to create directory structure
create_directory_structure() {
    for version in "${VERSIONS[@]}"; do
        mkdir -p "$BASE_DIR/addons"
        mkdir -p "$BASE_DIR/config"
    done
}

# Function to create docker-compose.yaml for Odoo 14
create_docker_compose_14() {
    cat > "$BASE_DIR/docker-compose.yaml" << 'EOF'
---
services:
  odoo14:
    container_name: odoo14
    image: moutazmuhammad/odoo:14.0
    restart: always 
    depends_on:
      - db14
    ports:
      - "1469:8069"
      - "1472:8072"
    environment:
      - DB_HOST=db14
      - DB_PORT=5432
      - DB_USER=odoo14
      - DB_PASSWORD=odoo14
    volumes:
      - odoo14-web-data:/var/lib/odoo
      - ./config:/etc/odoo
      - ./addons:/mnt/extra-addons
      
  db14:
    container_name: db14
    image: postgres:14
    restart: always 
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo14
      - POSTGRES_USER=odoo14
    volumes:
      - odoo14-db-data:/var/lib/postgresql/data

volumes:
  odoo14-web-data:
  odoo14-db-data:
EOF
}

# Function to create odoo.conf for Odoo 14
create_odoo_conf_14() {
    cat > "$BASE_DIR/config/odoo.conf" << 'EOF'
[options]
admin_passwd = admin14
db_host = db14
db_port = 5432
db_user = odoo14
db_password = odoo14

addons_path = /opt/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo
EOF
}

# Function to start Docker containers
start_containers() {
    for version in "${VERSIONS[@]}"; do
        echo "[INFO] Starting Odoo ${version} containers..."
        cd "$BASE_DIR"
        docker-compose up -d
        echo "[INFO] Odoo ${version} containers started"
    done
}

# Main execution
echo "[INFO] Setting up Odoo development environment..."

# Check and install prerequisites
check_install_docker
check_install_docker_compose

# Create directory structure
create_directory_structure

# Create configuration files
create_docker_compose_14
create_odoo_conf_14

# Start containers
start_containers

echo -e "\n\033[1;32m+###############################################################################################################################+\033[0m"
echo -e "\033[1;32m  ✅  Odoo development environment setup complete! Your Odoo development environment is ready for use. Here’s how to get started: \033[0m"
echo -e "\n\033[1;32m+###############################################################################################################################+\033[0m"
echo -e "\033[1;32m                                                           \033[0m"
echo -e "\033[1;34m  🔧 **Working with Odoo:**                                 \033[0m"
echo -e "\033[1;34m      ➤ You can access Odoo 14 at: \033[1;36m🔗 http://localhost:1469   \033[0m"
echo -e "\033[1;32m                                                           \033[0m"
echo -e "\033[1;34m  💡 **How to add custom modules:**                         \033[0m"
echo -e "\033[1;34m          1. Navigate to the 'addons' directory for the version of Odoo you want to work with: \033[0m"
echo -e "\033[1;34m             - Odoo 14: $BASE_DIR/addons                    \033[0m"
echo -e "\033[1;34m          2. Place your custom modules inside the respective 'addons' folder. \033[0m"
echo -e "\033[1;34m          3. **Important:** If your custom modules are not detected by Odoo, you might need to add the path to your 'addons' directory in the corresponding \`odoo.conf\` file. \033[0m"
echo -e "\033[1;34m             - You can find the \`odoo.conf\` file at:               \033[0m"
echo -e "\033[1;34m               - Odoo 14: $BASE_DIR/config/odoo.conf        \033[0m"
echo -e "\033[1;32m                                                           \033[0m"
echo -e "\033[1;34m  💡 **Commands created:**                                  \033[0m"
echo -e "\033[1;34m       ➤ \033[1;36mdocker stop odoo14\033[0m                                            \033[0m"
echo -e "\033[1;34m       ➤ \033[1;36mdocker start odoo14\033[0m                                           \033[0m"
echo -e "\033[1;34m       ➤ \033[1;36mdocker restart odoo14\033[0m                                         \033[0m"
echo -e "\033[1;32m                                                           \033[0m"
echo -e "\033[1;34m  🚀 **Development Tips:**                                  \033[0m"
echo -e "\033[1;34m      - Use Docker Compose to manage the environment easily.   \033[0m"
echo -e "\033[1;34m      - Your changes will take effect after restarting the respective Odoo container. \033[0m"
echo -e "\033[1;32m                                                           \033[0m"
echo -e "\033[1;32m  ✅  To view real-time logs for Odoo, run the following commands: \033[0m"
echo -e "\033[1;32m      - For Odoo 14: \033[1;36mdocker logs -f odoo14\033[0m \033[1;32m \033[0m"
echo -e "\033[1;32m                                                           \033[0m"
echo -e "\033[1;32m  Best regards,                                             \033[0m"
echo -e "\033[1;32m  Moutaz Muhammad                                           \033[0m"
echo -e "\n\033[1;32m+###############################################################################################################################+\033[0m"


