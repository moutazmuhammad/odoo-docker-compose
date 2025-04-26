#!/bin/bash

################################################################################
# Backup Odoo Databases and Upload to DigitalOcean Spaces
# Author: Moutaz Muhammad
# Description: Downloads and uploads both dump and zip backups of Odoo databases.
################################################################################

# === Configuration ===
ADMIN_PASSWORD="ODOO_ADMIN_PASSWORD"
DOWNLOAD_DIR="all_backups"
DIGITALOCEAN_BUCKET_NAME="DIGITAL_OCEAN_BUCKET"
BACKUP_URL_PATH="/web/database/backup"
LIST_URL_PATH="/web/database/list"
KEEP_BACKUPS=7
DRY_RUN=false  # Set to true for testing without uploading

# === Color Codes ===
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

# === Logger ===
log() {
    local level="$1"
    shift
    local message="$@"
    local time_stamp
    time_stamp=$(date '+%Y-%m-%d %H:%M:%S')
    case "$level" in
        INFO) echo -e "[${time_stamp}] ${GREEN}[INFO]${NC} $message" ;;
        WARN) echo -e "[${time_stamp}] ${YELLOW}[WARN]${NC} $message" ;;
        ERROR) echo -e "[${time_stamp}] ${RED}[ERROR]${NC} $message" ;;
        *) echo -e "[${time_stamp}] $message" ;;
    esac
}

# === Dependencies ===
install_dependencies() {
    local deps=("s3cmd" "curl" "unzip" "jq" "pg_dump")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log WARN "$dep not found. Installing..."
            apt-get update && apt-get install -y "$dep"
        fi
    done
}

# === Cleanup Old Backups ===
cleanup_old_backups() {
    local bucket_path="$1"
    local files file_count files_to_delete_list

    files=$(s3cmd ls "$bucket_path" | sort | awk '{print $4}')
    [ -z "$files" ] && log INFO "No backups in $bucket_path" && return 0

    file_count=$(echo "$files" | wc -l)
    [ "$file_count" -le "$KEEP_BACKUPS" ] && return 0

    files_to_delete_list=$(echo "$files" | head -n $((file_count - KEEP_BACKUPS)))
    while read -r file; do
        [ -n "$file" ] && log INFO "Deleting old backup: $file" && s3cmd del "$file"
    done <<< "$files_to_delete_list"
}

# === Projects & Databases ===
declare -A projects
projects["PROJECT_NAME_$(curl -s ifconfig.me)"]="PROJECT_NAME|STAGE|http://localhost:8069,PROJECT_NAME|STAGE|http://localhost:8070"

# === Backup Function ===
perform_backup() {
    local format="$1"  # dump or zip
    local backup_ext; backup_ext=$([ "$format" == "dump" ] && echo "dump" || echo "zip")

    for project_name in "${!projects[@]}"; do
        IFS=',' read -ra db_infos <<< "${projects[$project_name]}"
        for db_info in "${db_infos[@]}"; do
            IFS='|' read -r project stage url <<< "$db_info"
            databases=$(curl -s -X POST "$url$LIST_URL_PATH" -H "Content-Type: application/json" -d '{}' | jq -r '.result[]')

            for db in $databases; do
                log INFO "Backing up $db ($format) from $url"
                backup_file="${db}.${backup_ext}"
                new_name="${db}_$(date +%Y-%m-%d).${backup_ext}"

                curl -sSf -X POST -F "master_pwd=$ADMIN_PASSWORD" -F "name=$db" -F "backup_format=$format" -o "$backup_file" "$url$BACKUP_URL_PATH"
                if [ $? -ne 0 ]; then
                    log ERROR "Failed to backup $db ($format)"
                    continue
                fi

                mv "$backup_file" "$new_name"
                mkdir -p "$DOWNLOAD_DIR"
                mv "$new_name" "$DOWNLOAD_DIR/"

                if [ "$format" == "zip" ] && ! unzip -t "${DOWNLOAD_DIR}/${new_name}" &>/dev/null; then
                    log ERROR "Corrupted ZIP for $db"
                    rm -f "${DOWNLOAD_DIR}/${new_name}"
                    continue
                fi

                if [ "$DRY_RUN" == false ]; then
                    upload_path="s3://${DIGITALOCEAN_BUCKET_NAME}/${project_name}/${stage}/${format}/${db}/"
                    if s3cmd put "${DOWNLOAD_DIR}/${new_name}" "$upload_path"; then
                        log INFO "Uploaded $db to $upload_path"
                        cleanup_old_backups "$upload_path"
                    else
                        log ERROR "Failed to upload $db to bucket"
                    fi
                fi

                rm -f "${DOWNLOAD_DIR}/${new_name}"
            done
        done
    done
}

# === Check Services Are Running ===
check_services() {
    log INFO "Checking status of relevant services..."
    systemctl list-units --type=service --all --no-pager | awk '{print $1}' | grep '\.service$' | grep -E '(odoo)' | while read -r svc; do
        if systemctl is-active --quiet "$svc"; then
            log INFO "$svc is running"
        else
            log WARN "$svc is not running (left stopped)"
        fi
    done
}

# === MAIN ===
main() {
    install_dependencies
    check_services
    perform_backup "dump"
    perform_backup "zip"
    log INFO "All backups complete!"
}

main "$@"

