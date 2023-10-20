# Odoo Deployment in Docker

## 1- Installing and configuring Docker
* Run the following commands to get system updates:
```sh
sudo apt-get update

sudo apt-get upgrade -y
```

* The following commands will install docker on your system:
```sh
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common


UBUNTU_RLS=$(lsb_release -rs)

if [[ ${UBUNTU_RLS:0:2} -le 21 ]] ; then

   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

   sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

else

   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

fi

sudo apt update

apt-cache policy docker-ce

sudo apt install -y docker-ce docker-compose

```

* check the docker installation status:
```sh
sudo systemctl status docker
```

* We add the current user to the docker group:
```sh
sudo usermod -aG docker $(whoami)
```

# 

## 2- Let's create a directory for Odoo Project containers:

```

{project}/
    |
    └── {stage}/
            |
            ├── postgresql/
            |
            ├── Dockerfile
            |
            ├── docker-compose.yml
            |
            ├── odoo/
            |
            ├── config/
            |       |
            |       └── odoo.conf
            |
            ├── logs/
            |
            └── addons/
                    |
                    └── requirements.txt


```


Let's create a directory structure for a separate project, give it a name, for example, "{project}":
```sh

mkdir {project}/{stage}
cd {project}/{stage}

mkdir config addons odoo logs postgresql
touch addons/requirements.txt

```

## 3- Let's create an Odoo configuration file - odoo.conf:
```sh
vim config/odoo.conf
```
Add the following text to the file:
```conf
[options]
admin_passwd = 44226688
xmlrpc_port = 8069
db_user = odoo
db_password = odoo
addons_path=
;dbfilter = ^%d$
list_db = True
log_db_level = warning
log_handler = :INFO
log_level = debug_rpc
logfile = /mnt/logs/odoo-server.log
logrotate = 3
limit_memory_hard = 2415919104
limit_memory_soft = 2013265920
limit_request = 81920
limit_time_cpu = 6000
limit_time_real = 12000
limit_time_real_cron = 0
max_cron_threads = 2
proxy_mode = True
workers = 3
```

Generation of the master password "MASTER_PASS" can be done as follows:
```sh
python3 -c 'import base64, os; print(base64.b64encode(os.urandom(72)))'
```
Paste the generated password into the configuration file in the admin_passwd parameter.


## 4- Creating a "docker-compose" configuration file:

```
docker network create exp-network
```

Let's create the "docker-compose.yml" configuration file with the command:
```sh
vim docker-compose.yml
```
Add the following text to the file:
```yaml
version: "3"
services:
  {project}-{stage}:
    build: .
    container_name: {project}-{stage}
    depends_on:
      - db
    restart: always
    environment:
      - VIRTUAL_HOST=www.yourdomain.com,yourdomain.com
      - LETSENCRYPT_HOST=www.yourdomain.com,yourdomain.com
      - VIRTUAL_PORT=8069
    volumes:
      - ./odoo:/var/lib/odoo
      - ./config:/etc/odoo
      - ./addons:/mnt/extra-addons
      - ./logs:/mnt/logs
    networks:
      - exp-network
  db:
    image: postgres:12
    container_name: {project}-{stage}-db
    restart: always
    command: postgres -c "max_connections=300"
    environment:
      - POSTGRES_DB=postgres
      - POSTGRES_PASSWORD=odoo
      - POSTGRES_USER=odoo
    volumes:
      - ./postgresql:/var/lib/postgresql/data
    logging:
      options:
        max-size: 50m
    networks:
      - exp-network
networks:
   exp-network:
     external: true
```


## 5- Creating a configuration file "Dockerfile"
First, check your current Linux user ID as follows:
```sh
sudo grep "^$(whoami):" /etc/passwd | cut -f 3 -d:
```
User ID (for example): 1000

In the same way, we will get the ID of the user group:
```sh
sudo grep "^$(whoami):" /etc/passwd | cut -f 4 -d:
```
User group ID (for example): 1000


Let's add a file to create a container:
```sh
vim Dockerfile
```

Add the following text to the file odoo:14.0:
```docker
FROM odoo:14.0
USER root
RUN usermod -u 1000 odoo && \
    groupmod -g 1000 odoo && \
    mkdir /var/lib/odoo/.local && \
    chown -R 1000:1000 /var/lib/odoo
COPY addons/requirements.txt .
RUN apt-get update && \
    apt-get install -y python3-pip && \
    pip3 install -r requirements.txt && \
    rm requirements.txt
USER odoo
```

Add the following text to the file odoo:11.0:
```docker
FROM odoo:11.0
USER root
RUN usermod -u 1000 odoo && \
    groupmod -g 1000 odoo && \
    mkdir /var/lib/odoo/.local && \
    chown -R 1000:1000 /var/lib/odoo
COPY addons/requirements.txt .
RUN echo "deb http://deb.debian.org/debian/ buster main" > /etc/apt/sources.list && \
    echo "deb http://deb.debian.org/debian/ buster-updates main" >> /etc/apt/sources.list && \
    echo "deb http://security.debian.org/ buster/updates main" >> /etc/apt/sources.list && \
    rm /etc/apt/sources.list.d/* && \
    apt-get update && \
    pip3 install -r requirements.txt && \
    rm requirements.txt
USER odoo
```

Let's try to run the container:
```sh
cd {project}/{stage}
```
```sh
docker-compose up -d
```

The process of downloading images and creating a container for the current project will begin.
To view the Odoo log, use the command:
```sh
tail -f logs/odoo-server.log
```
If the container creation was successful, stop the container with the command:
```sh
docker-compose down
```



## Clean Old Images
```sh
#!/bin/bash

# Get a list of image IDs for images with <none> tag
image_ids=$(docker images -f "dangling=true" -q)

# Check if there are any images to remove
if [ -n "$image_ids" ]; then
  # Remove each image by its ID
  for image_id in $image_ids; do
    docker rmi $image_id
  done
else
  echo "No images with <none> tag found."
fi
```


# Nginx - SSL Automation - Docker

### Docker-Comopse

```

nginx/
    |
    ├── docker-compose.yml
    |
    ├── acme/
    |
    ├── certbot/
    |       └── www/
    |       |
    |       └── conf/
    |
    ├── certs/
    |
    ├── html
    |
    ├── config/
    |
    ├── logs/
    |
    └── vhost.d/
```
```sh
mkdir NGINX
cd NGINX
mkdir acme certbot certbot/www certbot/conf certs config html logs vhost.d
```


```
vim docker-compose.yml
```

```yaml
version: '3'
services:
  nginx-proxy:
    image: nginxproxy/nginx-proxy:alpine
    container_name: nginx-proxy
    restart: always
    ports:
      - 80:80
      - 443:443
    volumes:
      - ./conf:/etc/nginx/conf.d
      - ./vhost:/etc/nginx/vhost.d
      - ./html:/usr/share/nginx/html
      - ./certs:/etc/nginx/certs:ro
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
      - ./log:/var/log/nginx
    networks:
      - exp-network

  # acme companion
  acme-companion:
    image: nginxproxy/acme-companion
    container_name: acme-companion
    volumes_from:
      - nginx-proxy
    volumes:
      - ./certs:/etc/nginx/certs:rw
      - ./acme:/etc/acme.sh
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - DEFAULT_EMAIL=m.muhammad@exp-sa.com
      - NGINX_DOCKER_GEN_CONTAINER=nginx
    networks:
      - exp-network
  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
    networks:
      - exp-network
networks:
  exp-network:
    external: true
```


```sh
docker-compose up -d
```


# 

## Configuring NGINX and Certbot - Old Way
Actions before starting the settings
Before setting up the NGINX configuration, you need to create a domain for the Odoo system, let's take the following domain name as an example: test.domain.com
Go to the domain control panel of your domain name registrar and add a new record with type A for the domain (subdomain) and specify the IP address of the server:


### Installing NGINX
To install NGINX, run the command:
```sh
sudo apt-get install -y nginx
```

### Installing Certbot
To install Certbot, run the commands:
```sh
sudo apt install snapd -y
sudo snap install certbot --classic
```

### The next steps will include:
- creating an NGINX configuration to obtain an SSL certificate for the domain;
- making changes to the configuration necessary to start the Odoo system with binding to the domain name.


### Creating an NGINX configuration file
Let's create an NGINX configuration file for the "test.domain.com" domain:
```sh
sudo vim /etc/nginx/sites-available/test.domain.com.conf
```

First, add the following text to it:
```conf
server {
   listen [::]:80;
   listen 80;
   server_name test.domain.com www.test.domain.com;
 }
```

We activate this configuration, for this we create a "sim-link" - a link to the file in the "/etc/nginx/sites-enabled" directory:
```sh
sudo ln -s /etc/nginx/sites-available/test.domain.com.conf /etc/nginx/sites-enabled/test.domain.com.conf
```
We test that the configuration is correct:
```sh
sudo nginx -t
```
Let's restart the NGINX service if there are no errors:
```sh
sudo nginx -s reload
```

### Obtaining an SSL certificate
Next, we will receive a certificate for our domain "test.domain.com":
```sh
sudo certbot -m "admin@domain.com" -d "test.domain.com" --non-interactive --agree-tos --nginx certonly
```
Result:
```
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for test.domain.com
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/test.domain.com/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/test.domain.com/privkey.pem
This certificate expires on 2023-09-24.
These files will be updated when the certificate renews.
Certbot has set up a scheduled task to automatically renew this certificate in the background.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

Let's replace the NGINX configuration settings for use with the Odoo system:
```sh
sudo vim /etc/nginx/sites-available/test.domain.com.conf
```

*-* We will use the following data if we install Odoo version 16 or higher:
```
map $http_upgrade $connection_upgrade {
  default upgrade;
  ''      close;
}

#odoo server
upstream odoo_test {
   server 127.0.0.1:18069;          # change the port base on docker compose file
}

upstream odoochat_test {
   server 127.0.0.1:18072;          # change the port base on docker compose file
}

server {
   listen [::]:80;
   listen 80;
   server_name test.domain.com www.test.domain.com;
   return 301 https://test.domain.com;
 }

server {
   listen [::]:443 ssl;
   listen 443 ssl;
   server_name www.test.domain.com;
   ssl_certificate /etc/letsencrypt/live/test.domain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/test.domain.com/privkey.pem;
   return 301 https://test.domain.com;
}

server {
   listen [::]:443 ssl http2;
   listen 443 ssl http2;
   server_name test.domain.com;
   ssl_certificate /etc/letsencrypt/live/test.domain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/test.domain.com/privkey.pem;


   # log
   access_log /var/log/nginx/test.domain.com.access.log;
   error_log /var/log/nginx/test.domain.com.error.log;
   proxy_read_timeout 720s;
   proxy_connect_timeout 720s;
   proxy_send_timeout 720s;

   # Redirect longpoll requests to odoo websocket port
   location /websocket {
      proxy_pass http://odoochat_test;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Real-IP $remote_addr;
   }

   # Redirect requests to odoo backend server
   location / {
      # Add Headers for odoo proxy mode
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_redirect off;
      proxy_pass http://odoo_test;
      client_max_body_size 512M;
   }

   location ~* /web/static/ {
      proxy_cache_valid 200 90m;
      proxy_buffering on;
      expires 864000;
      proxy_pass http://odoo_test;
   }

   location ~* /web/database/manager {
      allow 123.123.123.123;
      deny all;
      proxy_pass http://odoo_test;
   }

   location ~* /web/database/selector {
      allow 123.123.123.123;
      deny all;
      proxy_pass http://odoo_test;
   }
   
   # common gzip
   gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
   gzip on;
}
```

*-* Data for Odoo version 15 or below:
```
#odoo server
upstream odoo_test {
   server 127.0.0.1:18069;                # change the port base on docker compose file
}

upstream odoochat_test {
   server 127.0.0.1:18072;                # change the port base on docker compose file
}


server {
   listen [::]:80;
   listen 80;
   server_name test.domain.com www.test.domain.com;
   return 301 https://test.domain.com;
 }

server {
   listen [::]:443 ssl;
   listen 443 ssl;
   server_name www.test.domain.com;
   ssl_certificate /etc/letsencrypt/live/test.domain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/test.domain.com/privkey.pem;
   return 301 https://test.domain.com;
}

server {
   listen [::]:443 ssl http2;
   listen 443 ssl http2;
   server_name test.domain.com;
   ssl_certificate /etc/letsencrypt/live/test.domain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/test.domain.com/privkey.pem;

   # log
   access_log /var/log/nginx/test.domain.com.access.log;
   error_log /var/log/nginx/test.domain.com.error.log;
   proxy_read_timeout 720s;
   proxy_connect_timeout 720s;
   proxy_send_timeout 720s;

   # Add Headers for odoo proxy mode
   proxy_set_header X-Forwarded-Host $host;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header X-Forwarded-Proto $scheme;
   proxy_set_header X-Real-IP $remote_addr;

   # Redirect longpoll requests to odoo longpolling port
   location /longpolling {
      proxy_pass http://odoochat_test;
   }

   # Redirect requests to odoo backend server
   location / {
      proxy_redirect off;
      proxy_pass http://odoo_test;
      client_max_body_size 512M;
   }

   location ~* /web/static/ {
      proxy_cache_valid 200 90m;
      proxy_buffering on;
      expires 864000;
      proxy_pass http://odoo_test;
   }

   location ~* /web/database/manager {
      # allow 121.121.121.121;
      # deny all;
      proxy_pass http://odoo_test;
   }

   location ~* /web/database/selector {
      # allow 121.121.121.121;
      # deny all;
      proxy_pass http://odoo_test;
   }

   # common gzip
   gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
   gzip on;
}
```

### If You want to add another Subdomain which serve on another port on same server

```
#odoo server
upstream odoo_second_app {
   server 127.0.0.1:18070;                      # change the port base on docker compose file
}

upstream odoochat_second_app {
   server 127.0.0.1:18073;                      # change the port base on docker compose file
}

server {
   listen [::]:80;
   listen 80;
   server_name secondapp.domain.com www.secondapp.domain.com;
   return 301 https://secondapp.domain.com;
}

server {
   listen [::]:443 ssl;
   listen 443 ssl;
   server_name www.secondapp.domain.com;
   ssl_certificate /etc/letsencrypt/live/secondapp.domain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/secondapp.domain.com/privkey.pem;
   return 301 https://secondapp.domain.com;
}

server {
   listen [::]:443 ssl http2;
   listen 443 ssl http2;
   server_name secondapp.domain.com;
   ssl_certificate /etc/letsencrypt/live/secondapp.domain.com/fullchain.pem;
   ssl_certificate_key /etc/letsencrypt/live/secondapp.domain.com/privkey.pem;

   # log
   access_log /var/log/nginx/secondapp.domain.com.access.log;
   error_log /var/log/nginx/secondapp.domain.com.error.log;
   proxy_read_timeout 720s;
   proxy_connect_timeout 720s;
   proxy_send_timeout 720s;

   # Add Headers for odoo proxy mode
   proxy_set_header X-Forwarded-Host $host;
   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header X-Forwarded-Proto $scheme;
   proxy_set_header X-Real-IP $remote_addr;

   # Redirect longpoll requests to odoo longpolling port
   location /longpolling {
      proxy_pass http://odoochat_second_app;
   }

   # Redirect requests to odoo backend server
   location / {
      proxy_redirect off;
      proxy_pass http://odoo_second_app;
      client_max_body_size 512M;
   }

   location ~* /web/static/ {
      proxy_cache_valid 200 90m;
      proxy_buffering on;
      expires 864000;
      proxy_pass http://odoo_second_app;
   }

   location ~* /web/database/manager {
      # allow 121.121.121.121;
      # deny all;
      proxy_pass http://odoo_second_app;
   }

   location ~* /web/database/selector {
      # allow 121.121.121.121;
      # deny all;
      proxy_pass http://odoo_second_app;
   }

   # common gzip
   gzip_types text/css text/scss text/plain text/xml application/xml application/json application/javascript;
   gzip on;
}
```
We test that the configuration is correct and restart the NGINX service if there are no errors:
```sh
sudo nginx -t && sudo nginx -s reload
```

### Adding third-party modules
To connect third-party modules, go to the "addons" directory and clone the required repository:
```sh
cd {project}/{stage}/addons
```

Copy the standard Odoo themes for the website:
```sh
git clone -b 16.0 --single-branch --depth=1 https://github.com/odoo/design-themes
```


Modules with themes will be added to the {project}/{stage}/addons/design-themes directory, then you need to add this path to the Odoo configuration file to the "addons_path" parameter as follows:
```sh
vim {project}/{stage}/config/odoo.conf
```

Let's add the path to the modules:
```
addons_path=/mnt/extra-addons/design-themes
```

Let's restart the docker container with commands:
```sh
cd {project}/{stage} && docker-compose down && docker-compose up -d
```

In this way, we will add the other repositories and modules we need, for example, the backup module:
```sh
cd {project}/{stage}/addons && git clone -b 16.0 --single-branch --depth=1 https://github.com/Yenthe666/auto_backup.git
```

Let's add the path to the modules in the configuration file:
```
addons_path=/mnt/extra-addons/design-themes
     ,/mnt/extra-addons/auto_backup
```

> Note: To improve the readability of the configuration file, you can add directories with modules from a new line. At the same time, it is necessary to follow the following syntax - first insert four spaces, then a comma and the path to the directory.



## If you are using Docker Compose to manage multi-container applications, you can specify resource limits in your docker-compose.yml file using the resources section. Here's an example:

```yaml
version: '3'
services:
  my-container:
    image: my-image
    resources:
      limits:
        cpus: '0.5'
        memory: 512M
```
