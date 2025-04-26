import os
import subprocess
from pathlib import Path

#########################################################################################################################################
# Author: Moutaz Muhammad <moutazmuhamad@gmail.com>
# Support Windows and MAC

# Script to stop containers and remove volumes for docker-compose files
# found inside directories named odoo11 or odoo14 on Windows

# Setup odoo11 & odoo14 environment
# Invoke-RestMethod -Uri https://raw.githubusercontent.com/moutazmuhammad/odoo_docker/main/Dockerfile/scripts/windows_destroy.py | python
##########################################################################################################################################

# Set the default search path (default is the user's home directory)
search_path = os.environ.get("SEARCH_PATH", str(Path.home()))

# Directories to look inside
target_dirs = ["ODOO_WORK/odoo11", "ODOO_WORK/odoo14"]

def stop_containers_and_remove_volumes():
    print(f"[INFO] Searching for docker-compose.yaml files inside 'odoo11' or 'odoo14' in {search_path}...")

    for target in target_dirs:
        target_path = Path(search_path)
        # Walk through all directories under search_path
        for path in target_path.rglob("docker-compose.yaml"):
            # Check if path matches the target directory pattern
            if target.replace("/", os.sep) in str(path.parent):
                docker_compose_dir = str(path.parent)
                print(f"[INFO] Stopping containers and removing volumes in directory: {docker_compose_dir}")

                # Change directory and run docker-compose down -v
                try:
                    subprocess.run(["docker-compose", "down", "-v"], cwd=docker_compose_dir, check=True)
                    print(f"[INFO] Containers stopped and volumes removed in: {docker_compose_dir}")
                except subprocess.CalledProcessError as e:
                    print(f"[ERROR] Failed in {docker_compose_dir}: {e}")
    try:
        parent_dir = Path(search_path) / "ODOO_WORK"
        shutil.rmtree(parent_dir)
        print(f"[INFO] Directory removed: {parent_dir}")
    except Exception as e:
        print(f"[ERROR] Failed to remove directory {parent_dir}: {e}")

if __name__ == "__main__":
    print("[INFO] Uninstalling Docker Compose environments...")

    stop_containers_and_remove_volumes()

    print("\n✅ Docker Compose environments uninstalled successfully!")
