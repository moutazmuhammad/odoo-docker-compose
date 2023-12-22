#!/bin/bash

set -x

# Author Moutaz Muhammad <moutazmuhamad@gmail.com>
# This script works for python version 3.10.12 - ubuntu 22.04 (could work for other versions)

# Set project name
PROJECT_NAME="project-name"

echo "[INFO] Update and upgrade system"

apt update
apt upgrade -y


echo "[INFO] Install necessary packages"
apt install -y git python3-pip python3.10-venv build-essential wget python3-dev python3-venv \
    python3-wheel libfreetype6-dev libxml2-dev libzip-dev libldap2-dev libsasl2-dev \
    python3-setuptools node-less libjpeg-dev zlib1g-dev libpq-dev \
    libxslt1-dev libldap2-dev libtiff5-dev libjpeg8-dev libopenjp2-7-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev libsasl2-dev libldap2-dev xfonts-75dpi xfonts-base

wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb

apt --fix-broken install -y

echo "[INFO] Create Odoo user"
useradd -m -d /home/odoo -U -r -s /bin/bash odoo

echo "[INFO] Install PostgreSQL 14"
apt install -y postgresql-14
sudo su - postgres -c "psql -c \"CREATE USER odooprod WITH PASSWORD 'odooprod' SUPERUSER\""
sudo su - postgres -c "psql -c \"CREATE USER odoostage WITH PASSWORD 'odoostage' SUPERUSER\""
sudo su - postgres -c "psql -c \"ALTER USER odooprod WITH SUPERUSER; ALTER USER odoostage WITH SUPERUSER;\""

echo "[INFO] Install npm and less"
sudo apt-get install -y npm
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less less-plugin-clean-css
sudo apt-get install -y node-less

echo "[INFO] Install wkhtmltopdf"
sudo wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo dpkg -i wkhtmltox_0.12.5-1.bionic_amd64.deb
sudo apt install -f


echo "[INFO] Switch to odoo user"
su - odoo << EOF
cd /home/odoo

echo "[INFO] Clone Odoo repository"
git clone https://www.github.com/odoo/odoo --depth 1 --branch 14.0 odoo-14.0

echo "[INFO] Create and activate virtual environment"
python3.10 -m venv odoo-venv
source odoo-venv/bin/activate

echo "[INFO] Install dependencies"
pip3 install wheel
pip install pylibjpeg-libjpeg
pip3 install -r odoo-14.0/requirements.txt

echo "[INFO] Deactivate virtual environment"
deactivate

echo "[INFO] Create project directories"
mkdir /home/odoo/${PROJECT_NAME}-stage
mkdir /home/odoo/${PROJECT_NAME}-prod

EOF

echo "[INFO] Create log directories and set permissions"
mkdir -p /var/log/odoo
touch "/var/log/odoo/odoo-server-${PROJECT_NAME}-stage.log"
touch "/var/log/odoo/odoo-server-${PROJECT_NAME}-prod.log"
chown -R odoo:odoo /var/log/odoo

echo "[INFO] Create Odoo configuration files"
sudo bash -c "cat > /etc/${PROJECT_NAME}-stage.conf" << EOF
[options]
admin_passwd = 5XdF*CVGDf23i5I$
db_host = 127.0.0.1
db_port = False
db_user = odoostage
db_password = odoostage
addons_path = /home/odoo/odoo-14.0/addons,/home/odoo/odoo-14.0/odoo/addons
logfile = /var/log/odoo/odoo-server-${PROJECT_NAME}-stage.log
xmlrpc_port = 8096
longpolling_port = 8027
data_dir = /home/odoo/stage_data_dir
limit_memory_hard = 2415919104
limit_memory_soft = 2013265920
limit_request = 819200
limit_time_cpu = 60000
limit_time_real = 120000
max_cron_threads = 1
db_maxconn = 32
EOF

sudo bash -c "cat > /etc/${PROJECT_NAME}-prod.conf" << EOF
[options]
admin_passwd = 5XdF*CVGDf23i5I$
db_host = 127.0.0.1
db_port = False
db_user = odooprod
db_password = odooprod
addons_path = /home/odoo/odoo-14.0/addons,/home/odoo/odoo-14.0/odoo/addons
logfile = /var/log/odoo/odoo-server-${PROJECT_NAME}-prod.log
xmlrpc_port = 7851
longpolling_port = 7815
data_dir = /home/odoo/prod_data_dir
limit_memory_hard = 2415919104
limit_memory_soft = 2013265920
limit_request = 819200
limit_time_cpu = 60000
limit_time_real = 120000
max_cron_threads = 1
db_maxconn = 32
EOF

echo "[INFO] Create systemd service files"
sudo bash -c "cat > /etc/systemd/system/odoo-server-${PROJECT_NAME}-stage.service" << EOF
[Unit]
Description=Odoo14
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo14
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/home/odoo/odoo-venv/bin/python3 /home/odoo/odoo-14.0/odoo-bin -c /etc/${PROJECT_NAME}-stage.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF

sudo bash -c "cat > /etc/systemd/system/odoo-server-${PROJECT_NAME}-prod.service" << EOF
[Unit]
Description=Odoo14
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
SyslogIdentifier=odoo14
PermissionsStartOnly=true
User=odoo
Group=odoo
ExecStart=/home/odoo/odoo-venv/bin/python3 /home/odoo/odoo-14.0/odoo-bin -c /etc/${PROJECT_NAME}-prod.conf
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
EOF


