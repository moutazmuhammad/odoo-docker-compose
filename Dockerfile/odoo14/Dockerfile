FROM ubuntu:20.04
LABEL maintainer="Moutaz Muhammad <moutazmuhamad@gmail.com>"

ENV LANG=C.UTF-8
SHELL ["/bin/bash", "-c"]

# Python & dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    software-properties-common wget curl gnupg lsb-release && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    python3.8 python3.8-venv python3.8-dev build-essential wget && \
    ln -sf python3.8 /usr/bin/python3 && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.8 && \
    ln -sf /usr/local/bin/pip3 /usr/bin/pip && \
    pip install --no-cache-dir --upgrade setuptools wheel && \
    apt-get purge -y software-properties-common && \
    apt-get autoremove -y && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# System libs
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates libev-dev libjpeg-dev zlib1g-dev libpq-dev libxml2-dev libxslt1-dev \
    libldap2-dev libsasl2-dev libfreetype6-dev libzip-dev \
    libtiff5-dev libjpeg8-dev libopenjp2-7-dev liblcms2-dev libwebp-dev \
    libharfbuzz-dev libfribidi-dev libxcb1-dev libcairo2-dev pkg-config \
    node-less npm git && \
    apt-get update && apt-get install -y gosu && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# wkhtmltopdf
RUN apt-get update && apt-get install -y --no-install-recommends \
    fontconfig libxrender1 libxtst6 libx11-6 xfonts-75dpi xfonts-base && \
    wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb && \
    dpkg -i wkhtmltox_0.12.5-1.bionic_amd64.deb || apt-get install -f -y && \
    rm -f wkhtmltox_0.12.5-1.bionic_amd64.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# PostgreSQL client
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client-14 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Node tools
RUN npm install -g less less-plugin-clean-css rtlcss && npm cache clean --force

RUN useradd -m -d /home/odoo -U -r -s /bin/bash odoo

# Install Odoo
RUN git init /opt/odoo && \
    cd /opt/odoo && \
    git remote add origin https://github.com/odoo/odoo.git && \
    git fetch origin 1305e87a3873970ee5c0aa21bc749ba33375e517 --depth=1 && \
    git checkout 1305e87a3873970ee5c0aa21bc749ba33375e517 && \
    chown -R odoo:odoo /opt/odoo && \
    ln -s /opt/odoo/odoo-bin /usr/local/bin/odoo

# Install Python dependencies
COPY requirements.txt /
RUN pip3 install wheel setuptools && pip install --upgrade pip setuptools wheel && pip install --no-cache-dir -r /requirements.txt && rm -f /requirements.txt

# Copy configs and setup permissions
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

RUN chmod +x /entrypoint.sh && \
    chmod +x /usr/local/bin/wait-for-psql.py && \
    chown odoo /etc/odoo/odoo.conf && \
    chown odoo /entrypoint.sh && \
    mkdir -p /mnt/extra-addons && chown -R odoo /mnt/extra-addons && \
    mkdir -p /var/lib/odoo/sessions && \
    chown -R odoo:odoo /var/lib/odoo && \
    chmod -R 750 /var/lib/odoo

VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]
EXPOSE 8069 8071 8072
ENV ODOO_RC=/etc/odoo/odoo.conf

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
