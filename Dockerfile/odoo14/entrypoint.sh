#!/bin/bash
set -e

# Get the UID and GID of the mounted volume's owner (using /var/lib/odoo as reference)
HOST_UID=$(stat -c %u /var/lib/odoo)
HOST_GID=$(stat -c %g /var/lib/odoo)

# Get the current odoo user UID and GID
ODOO_UID=$(id -u odoo)
ODOO_GID=$(id -g odoo)

# Adjust odoo user UID/GID to match the host if they differ
if [ "$HOST_UID" != "$ODOO_UID" ] || [ "$HOST_GID" != "$ODOO_GID" ]; then
    echo "Adjusting odoo user UID:GID to match host ($HOST_UID:$HOST_GID)..."
    usermod -u $HOST_UID odoo 2>/dev/null
    groupmod -g $HOST_GID odoo 2>/dev/null

    # Update ownership of relevant directories
    echo "Fixing ownership of /var/lib/odoo, /mnt/extra-addons, and /home/odoo..."
    chown -R $HOST_UID:$HOST_GID /var/lib/odoo /mnt/extra-addons /home/odoo /etc/odoo
fi

# Set up database connection parameters
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo'}}}

DB_ARGS=()
function check_config() {
    param="$1"
    value="$2"
    if grep -q -E "^\s*\b${param}\b\s*=" "$ODOO_RC" ; then       
        value=$(grep -E "^\s*\b${param}\b\s*=" "$ODOO_RC" | cut -d " " -f3 | sed 's/["\n\r]//g')
    fi
    DB_ARGS+=("--${param}")
    DB_ARGS+=("${value}")
}
check_config "db_host" "$HOST"
check_config "db_port" "$PORT"
check_config "db_user" "$USER"
check_config "db_password" "$PASSWORD"

# Run Odoo as the odoo user
case "$1" in
    -- | odoo)
        shift
        if [[ "$1" == "scaffold" ]] ; then
            exec gosu odoo odoo "$@"
        else
            wait-for-psql.py "${DB_ARGS[@]}" --timeout=30
            exec gosu odoo odoo "$@" "${DB_ARGS[@]}"
        fi
        ;;
    -*)
        wait-for-psql.py "${DB_ARGS[@]}" --timeout=30
        exec gosu odoo odoo "$@" "${DB_ARGS[@]}"
        ;;
    *)
        exec gosu odoo "$@"
esac

exit 1