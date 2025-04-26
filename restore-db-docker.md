# How to dump & restore a PostgreSQL database from a docker container


## Method One: (zip)

### In your local server
- Copy zip db that you want to restore to remote server

```sh
scp -P 7812 database-name-10-25_12-07-30.zip  root@143.198.105.101:/home/odoo/path
```

### In the remote server

```sh
unzip database-name-10-25_12-07-30.zip -d ./project-name-db
```

```sh
cd project-name-db
```


- Restore using psql

1. create new database
```sh
docker exec -it project-name-prod-db bash

psql -U odoo -d postgres

CREATE DATABASE project-name_prod;
```

```sh
docker exec -i project-name-prod-db /bin/bash -c "PGPASSWORD=odoo pg_dump --username=odoo project-name_prod" < dump.sql
```



- Dump using psql
```sh
docker exec -i project-name-prod-db /bin/bash -c "PGPASSWORD=odoo pg_dump --username=odoo project-name_prod" > dump.sql
```

#

## Method Two: (dump)

### In your local server
- Copy zip db that you want to restore to remote server

```sh
scp -P 7812 database-name-10-25_15-20-37.dump  root@143.198.105.101:/home/odoo
```

### In the remote server


### In the remote server

- Restore using psql

1. create new database
```sh
docker exec -it project-name-prod-db bash

psql -U odoo -d postgres

CREATE DATABASE project-name_prod_two;
```

```sh
docker exec -i project-name-prod-db /bin/bash -c "PGPASSWORD=odoo  pg_restore --username=odoo  -d project-name_prod_two " < database-name-10-25_15-20-37.dump
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
WHERE datname = 'project-name_prod';
```


 ```sh
docker exec -it project-name-prod-db bash

psql -U odoo -d postgres

DROP DATABASE project-name_prod_two;
```

