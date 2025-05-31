import os
import subprocess
import sys
from pathlib import Path

#####################################################################################################################################################
# Author: Moutaz Muhammad <moutazmuhamad@gmail.com>
# Support Windows and MAC

# Setup odoo14 & odoo14 environment
# Invoke-RestMethod -Uri https://raw.githubusercontent.com/moutazmuhammad/odoo_docker/main/Dockerfile/odoo14/scripts/windows_setup_pg14.py | python
#####################################################################################################################################################

# Base directory for the project
BASE_DIR = os.environ.get('BASE_DIR', str(Path.cwd() / "ODOO14_pg14"))
os.makedirs(BASE_DIR, exist_ok=True)
VERSIONS = ["14"]

# Function to create directory structure
def create_directory_structure():
    for version in VERSIONS:
        os.makedirs(Path(BASE_DIR) / "addons", exist_ok=True)
        os.makedirs(Path(BASE_DIR) / "config", exist_ok=True)

# Function to create docker-compose.yaml for Odoo 14
def create_docker_compose_14():
    compose_content = '''---
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
'''
    with open(Path(BASE_DIR) / "docker-compose.yaml", "w") as f:
        f.write(compose_content)

# Function to create odoo.conf for Odoo 14
def create_odoo_conf_14():
    conf_content = '''[options]
admin_passwd = admin14
db_host = db14
db_port = 5432
db_user = odoo14
db_password = odoo14

addons_path = /opt/odoo/addons,/mnt/extra-addons
data_dir = /var/lib/odoo
'''
    with open(Path(BASE_DIR) / "config" / "odoo.conf", "w") as f:
        f.write(conf_content)

# Function to start Docker containers
def start_containers():
    for version in VERSIONS:
        print(f"[INFO] Starting Odoo {version} containers...")
        os.chdir(Path(BASE_DIR))
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
    print(f"{BLUE}      - You can access Odoo 14 at: http://localhost:1469{RESET}")
    print(f"{BLUE}  # How to add custom modules:{RESET}")
    print(f"{BLUE}          1. Navigate to the 'addons' directory for the version you want to work with:{RESET}")
    print(f"{BLUE}             - Odoo 14: {BASE_DIR}/addons{RESET}")
    print(f"{BLUE}          2. Place your custom modules inside the respective 'addons' folder.{RESET}")
    print(f"{BLUE}          3. If not detected, add the addons path inside the 'odoo.conf'.{RESET}")
    print(f"{BLUE}  # Development Tips:{RESET}")
    print(f"{BLUE}      - Use Docker Compose to manage the environment easily.{RESET}")
    print(f"{BLUE}      - Restart Odoo container to apply changes.{RESET}")
    print(f"{GREEN}  # To view real-time logs:{RESET}")
    print(f"{GREEN}      - For Odoo 14: {CYAN}docker logs -f odoo14{RESET}")
    print(f"{GREEN}  Best regards,{RESET}")
    print(f"{GREEN}  Moutaz Muhammad{RESET}")
    print(f"\n{GREEN}+{'#' * 118}+{RESET}")

# Main execution
if __name__ == "__main__":
    print("[INFO] Setting up Odoo development environment...")

    create_directory_structure()
    create_docker_compose_14()
    create_odoo_conf_14()
    start_containers()
    print_final_message()
