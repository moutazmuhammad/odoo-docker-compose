import os
import subprocess
import sys
from pathlib import Path

########################################################################################################################################################
# Author: Moutaz Muhammad <moutazmuhamad@gmail.com>
# Support Windows and MAC

# Setup odoo11 & postgresql 14
# Invoke-RestMethod -Uri https://raw.githubusercontent.com/moutazmuhammad/odoo_docker/main/Dockerfile/odoo11/scripts/windows_setup_pg14.py | python
# To upgrade module for terminal
# docker exec -u odoo -it odoo11 odoo -u <MODULE_NAME> -d <DB_NAME> -c /etc/odoo/odoo.conf
########################################################################################################################################################

# Base directory for the project
BASE_DIR = os.environ.get('BASE_DIR', str(Path.cwd() / "ODOO_WORK"))
os.makedirs(BASE_DIR, exist_ok=True)
VERSIONS = ["11"]

# Function to create directory structure
def create_directory_structure():
    for version in VERSIONS:
        os.makedirs(Path(BASE_DIR) / f"odoo{version}" / "addons", exist_ok=True)
        os.makedirs(Path(BASE_DIR) / f"odoo{version}" / "config", exist_ok=True)

# Function to create docker-compose.yaml for Odoo 11
def create_docker_compose_11():
    compose_content = '''---
services:
  odoo11:
    container_name: odoo11
    image: moutazmuhammad/odoo:11.3.7-14
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
'''
    with open(Path(BASE_DIR) / "odoo11" / "docker-compose.yaml", "w") as f:
        f.write(compose_content)

# Function to create odoo.conf for Odoo 11
def create_odoo_conf_11():
    conf_content = '''[options]
admin_passwd = admin11
db_host = db11
db_port = 5432
db_user = odoo11
db_password = odoo11

addons_path = /opt/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo
'''
    with open(Path(BASE_DIR) / "odoo11" / "config" / "odoo.conf", "w") as f:
        f.write(conf_content)

# Function to start Docker containers
def start_containers():
    for version in VERSIONS:
        print(f"[INFO] Starting Odoo {version} containers...")
        os.chdir(Path(BASE_DIR) / f"odoo{version}")
        subprocess.run(["docker-compose", "up", "-d"], check=True)
        print(f"[INFO] Odoo {version} containers started")

# Function to print final message
def print_final_message():
    GREEN = '\033[1;32m'
    BLUE = '\033[1;34m'
    CYAN = '\033[1;36m'
    RESET = '\033[0m'

    print(f"\n{GREEN}+{'#' * 118}+{RESET}")
    print(f"{GREEN} Odoo development environment setup complete! Your Odoo development environment is ready for use. Here’s how to get started: {RESET}")
    print(f"\n{GREEN}+{'#' * 118}+{RESET}")
    print(f"{BLUE}  # Working with Odoo:{RESET}")
    print(f"{BLUE}      - You can access Odoo 11 at: {CYAN}🔗 http://localhost:1169{RESET}")
    print(f"{BLUE}  # How to add custom modules:{RESET}")
    print(f"{BLUE}          1. Navigate to the 'addons' directory for the version you want to work with:{RESET}")
    print(f"{BLUE}             - Odoo 11: {BASE_DIR}/odoo11/addons{RESET}")
    print(f"{BLUE}          2. Place your custom modules inside the respective 'addons' folder.{RESET}")
    print(f"{BLUE}          3. If not detected, add the addons path inside the 'odoo.conf'.{RESET}")
    print(f"{BLUE}  # Development Tips:{RESET}")
    print(f"{BLUE}      - Use Docker Compose to manage the environment easily.{RESET}")
    print(f"{BLUE}      - Restart Odoo container to apply changes.{RESET}")
    print(f"{GREEN}  # To view real-time logs:{RESET}")
    print(f"{GREEN}      - For Odoo 11: {CYAN}docker logs -f odoo11{RESET}")
    print(f"{GREEN}  Best regards,{RESET}")
    print(f"{GREEN}  Moutaz Muhammad{RESET}")
    print(f"\n{GREEN}+{'#' * 118}+{RESET}")

# Main execution
if __name__ == "__main__":
    print("[INFO] Setting up Odoo development environment...")

    create_directory_structure()
    create_docker_compose_11()
    create_odoo_conf_11()
    start_containers()
    print_final_message()
