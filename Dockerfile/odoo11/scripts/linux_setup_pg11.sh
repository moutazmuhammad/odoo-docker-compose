#!/bin/bash

##########################################################################################################################################
# Author: Moutaz Muhammad <moutazmuhamad@gmail.com>
# Supports Ubuntu 16, 20, 22, 24, CentOS, and Red Hat

# Setup odoo11 & postgresql11
# curl -s https://raw.githubusercontent.com/moutazmuhammad/odoo-docker-compose/main/Dockerfile/odoo11/scripts/linux_setup_pg11.sh | bash

# To upgrade module from terminal
# docker exec -u odoo -it odoo11 odoo -u <MODULE_NAME> -d <DB_NAME> -c /etc/odoo/odoo.conf

# Access DB
# docker exec -it db11 bash
#  psql -U odoo11 -d <DB_NAME>
# update res_users set password='admin' where login='admin';
##########################################################################################################################################

set -e

# Base directory for the project
BASE_DIR="${BASE_DIR:-$PWD/ODOO11_pg11}"
mkdir -p "$BASE_DIR"
VERSIONS=("11")

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
            sudo systemctl enable docker
            sudo systemctl start docker
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
    mkdir -p "$BASE_DIR/addons"
    mkdir -p "$BASE_DIR/config"
}

# Function to create docker-compose.yaml for Odoo 11
create_docker_compose_11() {
    cat > "$BASE_DIR/docker-compose.yaml" << 'EOF'
---
services:
  odoo11:
    container_name: odoo11
    image: moutazmuhammad/odoo:11.3.7-11
    restart: always 
    depends_on:
      - db11
    ports:
      - "1169:8069"
      - "1172:8072"
    environment:
      - DB_HOST=db11
      - DB_PORT=5432
      - DB_USER=odoo11
      - DB_PASSWORD=odoo11
    volumes:
      - odoo11-web-data:/var/lib/odoo
      - ./config:/etc/odoo
      - ./addons:/mnt/extra-addons
      
  db11:
    container_name: db11
    image: postgres:11
    restart: always 
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo11
      - POSTGRES_USER=odoo11
    volumes:
      - odoo11-db-data:/var/lib/postgresql/data

volumes:
  odoo11-web-data:
  odoo11-db-data:
EOF
}

# Function to create odoo.conf for Odoo 11
create_odoo_conf_11() {
    cat > "$BASE_DIR/config/odoo.conf" << 'EOF'
[options]
admin_passwd = admin11
db_host = db11
db_port = 5432
db_user = odoo11
db_password = odoo11

addons_path = /opt/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo
EOF
}

# Function to start Docker containers
start_containers() {
    echo "[INFO] Starting Odoo containers..."
    cd "$BASE_DIR"
    docker-compose up -d
    echo "[INFO] Odoo containers started"
}

# Main execution
echo "[INFO] Setting up Odoo development environment..."

check_install_docker
check_install_docker_compose
create_directory_structure
create_docker_compose_11
create_odoo_conf_11
start_containers

# Success banner
echo -e "\n\033[1;32m+###############################################################################################################################+\033[0m"
echo -e "\033[1;32m  ✅  Odoo development environment setup complete! Your Odoo development environment is ready for use. Here’s how to get started: \033[0m"
echo -e "\n\033[1;32m+###############################################################################################################################+\033[0m"
echo -e "\033[1;34m  🔧 **Working with Odoo:**                                 \033[0m"
echo -e "\033[1;34m      ➤ You can access Odoo 11 at: \033[1;36m🔗 http://localhost:1169   \033[0m"
echo -e "\033[1;34m  💡 **How to add custom modules:**                         \033[0m"
echo -e "\033[1;34m          1. Navigate to the 'addons' directory:            \033[0m"
echo -e "\033[1;34m             - Odoo 11: $BASE_DIR/addons                    \033[0m"
echo -e "\033[1;34m          2. Place your custom modules inside it.           \033[0m"
echo -e "\033[1;34m          3. Update \`odoo.conf\` if needed:                 \033[0m"
echo -e "\033[1;34m             - Path: $BASE_DIR/config/odoo.conf             \033[0m"
echo -e "\033[1;34m          4. Restart Odoo using:                            \033[0m"
echo -e "\033[1;34m             - \033[1;36mdocker restart odoo11\033[0m                    \033[0m"
echo -e "\033[1;34m  💡 **Commands:**                                          \033[0m"
echo -e "\033[1;34m       ➤ \033[1;36mdocker restart odoo11\033[0m                              \033[0m"
echo -e "\033[1;34m       ➤ \033[1;36mdocker start odoo11\033[0m                                \033[0m"
echo -e "\033[1;34m       ➤ \033[1;36mdocker stop odoo11\033[0m                                 \033[0m"
echo -e "\033[1;34m  🚀 **Tips:**                                              \033[0m"
echo -e "\033[1;34m      - Use Docker Compose to manage the environment.       \033[0m"
echo -e "\033[1;34m      - Restart the container after code/config changes.    \033[0m"
echo -e "\033[1;34m      - View real-time logs using: \033[1;36mdocker logs -f odoo11\033[0m     \033[0m"
echo -e "\033[1;32m                                                           \033[0m"
echo -e "\033[1;32m  Best regards,                                             \033[0m"
echo -e "\033[1;32m  Moutaz Muhammad                                           \033[0m"
echo -e "\n\033[1;32m+###############################################################################################################################+\033[0m"
