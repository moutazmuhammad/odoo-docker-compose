#!/bin/bash

#################################################################################################################
# Author: Moutaz Muhammad <moutazmuhamad@gmail.com>
# Modified to support Ubuntu 16, 20, 22, 24, CentOS, and Red Hat

# curl -s https://raw.githubusercontent.com/moutazmuhammad/odoo-docker-compose/main/Dockerfile/setup.sh | bash
#################################################################################################################
set -e

# Base directory for the project
BASE_DIR="${BASE_DIR:-$PWD/EXPERT}"
mkdir -p $BASE_DIR
VERSIONS=("11" "14")

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
            # Ubuntu-specific Docker installation
            sudo apt-get update
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ]; then
            if [[ "$VER" == 7.* ]]; then
                # CentOS/RHEL 7 uses yum
                sudo yum remove docker docker-common docker-selinux docker-engine
                sudo yum install -y yum-utils device-mapper-persistent-data lvm2
                if [ "$OS" == "centos" ]; then
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                elif [ "$OS" == "rhel" ]; then
                    sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
                fi
                sudo yum install docker-ce
            else
                # CentOS/RHEL 8 and later use dnf
                sudo dnf -y install dnf-plugins-core
                if [ "$OS" == "centos" ]; then
                    sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                elif [ "$OS" == "rhel" ]; then
                    sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
                fi
                sudo dnf install docker-ce docker-ce-cli containerd.io
            fi
            # Start and enable Docker service for CentOS/RHEL
            sudo systemctl enable docker.service
            sudo systemctl start docker.service
        else
            echo "Unsupported OS: $OS"
            exit 1
        fi
        # Add user to docker group for all supported OS
        sudo usermod -aG docker $USER
        echo "Docker installed successfully."
    else
        echo "Docker is already installed."
    fi
}

# Function to check and install Docker Compose
check_install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose not found. Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed successfully."
    else
        echo "Docker Compose is already installed."
    fi
}

# Function to create directory structure
create_directory_structure() {
    for version in "${VERSIONS[@]}"; do
        mkdir -p "$BASE_DIR/odoo${version}/addons"
        mkdir -p "$BASE_DIR/odoo${version}/config"
    done
}

# Function to create docker-compose.yaml for Odoo 14
create_docker_compose_14() {
    cat > "$BASE_DIR/odoo14/docker-compose.yaml" << 'EOF'
version: '3.3'
services:
  odoo14:
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

# Function to create docker-compose.yaml for Odoo 11
create_docker_compose_11() {
    cat > "$BASE_DIR/odoo11/docker-compose.yaml" << 'EOF'
version: '3.3'
services:
  odoo11:
    image: moutazmuhammad/odoo:11.0
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
    image: postgres:14
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

# Function to create odoo.conf for Odoo 14
create_odoo_conf_14() {
    cat > "$BASE_DIR/odoo14/config/odoo.conf" << 'EOF'
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

# Function to create odoo.conf for Odoo 11
create_odoo_conf_11() {
    cat > "$BASE_DIR/odoo11/config/odoo.conf" << 'EOF'
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
    for version in "${VERSIONS[@]}"; do
        echo "Starting Odoo ${version} containers..."
        cd "$BASE_DIR/odoo${version}"
        docker-compose up -d
        echo "Odoo ${version} containers started"
    done
}

create_restart_commands() {
    echo "Creating custom restart commands..."

    # Make sure we have write permission to /usr/local/bin/
    sudo chmod u+w /usr/local/bin/

    # Create restart-odoo11 command
    echo '#!/bin/bash' | sudo tee /usr/local/bin/restart-odoo11 > /dev/null
    echo "cd $BASE_DIR/odoo11 && docker-compose restart" | sudo tee -a /usr/local/bin/restart-odoo11 > /dev/null
    sudo chmod +x /usr/local/bin/restart-odoo11

    # Create restart-odoo14 command
    echo '#!/bin/bash' | sudo tee /usr/local/bin/restart-odoo14 > /dev/null
    echo "cd $BASE_DIR/odoo14 && docker-compose restart" | sudo tee -a /usr/local/bin/restart-odoo14 > /dev/null
    sudo chmod +x /usr/local/bin/restart-odoo14
    
    # Create stop-odoo11 command
    echo '#!/bin/bash' | sudo tee /usr/local/bin/stop-odoo11 > /dev/null
    echo "cd $BASE_DIR/odoo11 && docker-compose down" | sudo tee -a /usr/local/bin/stop-odoo11 > /dev/null
    sudo chmod +x /usr/local/bin/restart-odoo11

    # Create stop-odoo14 command
    echo '#!/bin/bash' | sudo tee /usr/local/bin/stop-odoo14 > /dev/null
    echo "cd $BASE_DIR/odoo14 && docker-compose down" | sudo tee -a /usr/local/bin/stop-odoo14 > /dev/null
    sudo chmod +x /usr/local/bin/restart-odoo14

    # Create start-odoo11 command
    echo '#!/bin/bash' | sudo tee /usr/local/bin/start-odoo11 > /dev/null
    echo "cd $BASE_DIR/odoo11 && docker-compose up -d" | sudo tee -a /usr/local/bin/start-odoo11 > /dev/null
    sudo chmod +x /usr/local/bin/restart-odoo11

    # Create start-odoo14 command
    echo '#!/bin/bash' | sudo tee /usr/local/bin/start-odoo14 > /dev/null
    echo "cd $BASE_DIR/odoo14 && docker-compose up -d" | sudo tee -a /usr/local/bin/start-odoo14 > /dev/null
    sudo chmod +x /usr/local/bin/restart-odoo14
    
}

# Main execution
echo "Setting up Odoo development environment..."

# Check and install prerequisites
check_install_docker
check_install_docker_compose

# Create directory structure
create_directory_structure

# Create configuration files
create_docker_compose_14
create_docker_compose_11
create_odoo_conf_14
create_odoo_conf_11

# Start containers
start_containers
create_restart_commands


echo -e "\n+-----------------------------------------------------------+"
echo -e "| ✅  Odoo development environment setup complete!         |"
echo -e "| Your Odoo development environment is ready for use.      |"
echo -e "| Here’s how to get started:                               |"
echo -e "|                                                           |"
echo -e "| 🔧 **Working with Odoo:**                                 |"
echo -e "|  ➤ You can access Odoo 14 at: 🔗 http://localhost:1469   |"
echo -e "|  ➤ You can access Odoo 11 at: 🔗 http://localhost:1169   |"
echo -e "|                                                           |"
echo -e "| 💡 **How to add custom modules:**                         |"
echo -e "|  1. Navigate to the 'addons' directory for the version    |"
echo -e "|     of Odoo you want to work with:                        |"
echo -e "|     - Odoo 14: $BASE_DIR/odoo14/addons                    |"
echo -e "|     - Odoo 11: $BASE_DIR/odoo11/addons                    |"
echo -e "|  2. Place your custom modules inside the respective 'addons'|"
echo -e "|     folder.                                               |"
echo -e "|  3. **Important:** If your custom modules are not detected|"
echo -e "|     by Odoo, you might need to add the path to your       |"
echo -e "|     'addons' directory in the corresponding `odoo.conf`   |"
echo -e "|     file.                                                 |"
echo -e "|     - You can find the `odoo.conf` file at:               |"
echo -e "|       - Odoo 14: $BASE_DIR/odoo14/config/odoo.conf        |"
echo -e "|       - Odoo 11: $BASE_DIR/odoo11/config/odoo.conf        |"
echo -e "|  4. Restart Odoo to see the new modules appear by running |"
echo -e "|     one of the following commands:                        |"
echo -e "|     - Restart Odoo 14: restart-odoo14                    |"
echo -e "|     - Restart Odoo 11: restart-odoo11                    |"
echo -e "|                                                           |"
echo -e "| 💡 **Commands created:**                                  |"
echo -e "|  ➤ stop-odoo11                                            |"
echo -e "|  ➤ stop-odoo14                                            |"
echo -e "|  ➤ start-odoo11                                           |"
echo -e "|  ➤ start-odoo14                                           |"
echo -e "|  ➤ restart-odoo11                                         |"
echo -e "|  ➤ restart-odoo14                                         |"
echo -e "|                                                           |"
echo -e "| 🚀 **Development Tips:**                                  |"
echo -e "|  - Use Docker Compose to manage the environment easily.   |"
echo -e "|  - Your changes will take effect after restarting the     |"
echo -e "|    respective Odoo container.                             |"
echo -e "|                                                           |"
echo -e "| Best regards,                                             |"
echo -e "| Moutaz Muhammad                                           |"
echo -e "+-----------------------------------------------------------+"

