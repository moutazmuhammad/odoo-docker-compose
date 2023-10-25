# How to dump & restore a PostgreSQL database from a docker container


## Method One: (zip)

### In your local server
- Copy zip db that you want to restore to remote server

```sh
scp -P 7812 zuhair_preprod_db_prod_2023-10-25_12-07-30.zip  root@143.198.105.101:/home/odoo/ZUHAIR/ZUHAIR-PROD
```

### In the remote server

```sh
unzip zuhair_preprod_db_prod_2023-10-25_12-07-30.zip -d ./zuhair-db
```

```sh
cd zuhair-db
```


- Restore using psql

1. create new database
```sh
docker exec -it zuhair-prod-db bash

psql -U odoo -d postgres

CREATE DATABASE zuhair_prod;
```

```sh
docker exec -i zuhair-prod-db /bin/bash -c "PGPASSWORD=odoo pg_dump --username=odoo zuhair_prod" < dump.sql
```



- Dump using psql
```sh
docker exec -i zuhair-prod-db /bin/bash -c "PGPASSWORD=odoo pg_dump --username=odoo zuhair_prod" > dump.sql
```

#

## Method Two: (dump)

### In your local server
- Copy zip db that you want to restore to remote server

```sh
scp -P 7812 zuhair_preprod_db_prod_2023-10-25_15-20-37.dump  root@143.198.105.101:/home/odoo
```

### In the remote server


### In the remote server

- Restore using psql

1. create new database
```sh
docker exec -it zuhair-prod-db bash

psql -U odoo -d postgres

CREATE DATABASE zuhair_prod_two;
```

```sh
docker exec -i zuhair-prod-db /bin/bash -c "PGPASSWORD=odoo  pg_restore --username=odoo  -d zuhair_prod_two " < zuhair_preprod_db_prod_2023-10-25_15-20-37.dump
```



# Change admin password
```sh
docker exec -it  <container-name> psql -U <dataBaseUserName> <dataBaseName>
```

```sh
UPDATE res_users SET password='admin' WHERE id=2;
```



# Force remove Database

```sql
-- This will disconnect all users connected to the database
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'zuhair_prod';
```


 ```sh
docker exec -it zuhair-prod-db bash

psql -U odoo -d postgres

DROP DATABASE zuhair_prod_two;
```

