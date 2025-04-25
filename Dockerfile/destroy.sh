#!/bin/bash

###########################################################################
# Author: Moutaz Muhammad <moutazmuhamad@gmail.com>
# Script to stop containers and remove volumes for docker-compose files
# found inside directories named odoo11 or odoo14, no need for full path
###########################################################################
set -e

# Default search path (root of the file system or user's home, or adjust as needed)
SEARCH_PATH="${SEARCH_PATH:-$HOME}"

# Directories to search for docker-compose.yml files
TARGET_DIRS=("EXPERT/odoo11" "EXPERT/odoo14")

# Function to find docker-compose.yml files inside directories named odoo11 or odoo14
stop_containers_and_remove_volumes() {
    echo "Searching for docker-compose.yml files inside directories named 'odoo11' or 'odoo14' in $SEARCH_PATH..."

    # Use find to search for directories named odoo11 or odoo14 containing docker-compose.yml files
    for dir in "${TARGET_DIRS[@]}"; do
        # Find the docker-compose.yml file in odoo11 or odoo14 directories
        find "$SEARCH_PATH" -type f -path "*/$dir/docker-compose.yml" | while read docker_compose_file; do
            # Extract the directory containing docker-compose.yml
            docker_compose_dir=$(dirname "$docker_compose_file")
            echo "Stopping containers and removing volumes in directory: $docker_compose_dir"
            
            # Change to the directory containing the docker-compose.yml file
            cd "$docker_compose_dir" || continue
            
            # Stop containers and remove volumes
            docker-compose down -v
            echo "Containers stopped and volumes removed in: $docker_compose_dir"
        done
    done
}

# Main execution
echo "Uninstalling Docker Compose environments..."

# Stop containers and remove volumes for matching directories
stop_containers_and_remove_volumes

echo -e "\n✅ Docker Compose environments uninstalled successfully!"
