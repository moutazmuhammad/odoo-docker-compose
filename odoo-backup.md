# ODOO BACKUP

## Create Python script

```sh
vim projects-db.py
```
```py
import subprocess

# Define the projects with their respective information
projects = {
    # "project1": [{"ADMIN_PASSWORD": "password1", "url": "https://example1.com/web/database/backup"}]
    "nadi": [{"DB_NAME": "Nadi_dev_db", "ADMIN_PASSWORD": "44yfpkqzx7g4", "URL": "https://nadi-dev.exp-sa.com/web/database/backup"}, 
             {"DB_NAME": "Nadi_preprod_db", "ADMIN_PASSWORD": "44yfpkqzx7g4", "URL": "https://nadi.exp-sa.com/web/database/backup"}],
    "zuhair": [{"DB_NAME": "zuhair_dev_db_new", "ADMIN_PASSWORD": "44yfpkqzx7g4", "URL": "https://zuhair-dev.exp-sa.com/web/database/backup"},
               {"DB_NAME": "zuhair_befor_preprod_db", "ADMIN_PASSWORD": "44yfpkqzx7g4", "URL": "https://zuhair-preprod.exp-sa.com/web/database/backup"},
               {"DB_NAME": "zuhair_preprod_db_AAA", "ADMIN_PASSWORD": "44yfpkqzx7g4", "URL": "https://zuhair.exp-sa.com/web/database/backup"},
               {"DB_NAME": "zuhair_preprod_db_meeting", "ADMIN_PASSWORD": "44yfpkqzx7g4", "URL": "https://zuhair.exp-sa.com/web/database/backup"},
               {"DB_NAME": "zuhair_preprod_db_prod", "ADMIN_PASSWORD": "44yfpkqzx7g4", "URL": "https://zuhair.exp-sa.com/web/database/backup"}],
}


for project_name, databases in projects.items():
    # Loop through databases in the project
    FOLDER_NAME = project_name
    for database_info in databases:
        DB_NAME = database_info["DB_NAME"]
        ADMIN_PASSWORD = database_info["ADMIN_PASSWORD"]
        URL = database_info["URL"]

        try:
            # Run the Bash script with the specified arguments
            subprocess.run(['./backup.sh', DB_NAME, ADMIN_PASSWORD, URL, FOLDER_NAME], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error: {e}")

```



## Create Bash script
```sh
vim backup.sh
```

```sh
#!/bin/bash

# Define DigitalOcean Spaces credentials
DO_BUCKET_NAME='odex-backups'

# Check if required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <DB_NAME> <ADMIN_PASSWORD> <URL> <FOLDER_NAME>"
    exit 1
fi

# Assign input arguments to variables
DB_NAME=$1
ADMIN_PASSWORD=$2
URL=$3
FOLDER_NAME=$4


# Create backup using curl
curl -X POST \
  -F "master_pwd=${ADMIN_PASSWORD}" \
  -F "name=${DB_NAME}" \
  -F "backup_format=zip" \
  -o "${DB_NAME}.zip" \
  "${URL}" || { echo "Backup failed"; exit 1; }

# Upload backup to DigitalOcean Spaces
s3cmd put "${DB_NAME}.zip" "s3://${DO_BUCKET_NAME}/${FOLDER_NAME}/" || { echo "Upload to Spaces failed"; exit 1; }

# Clean up local backup file
rm -rf "${DB_NAME}.zip"

```
```sh
chmod +x backup.sh
```

## Create Cron Job
```sh
crontab -e
```
```
0 1 * * * /usr/bin/python3 /home/puppexuser/odex-backups/projects-db.py > /home/puppexuser/odex-backups/backup.log 2>&1
```
