# db-backup
Code inspired from [PostgreSQL.org => Automated Backup on Linux](https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux). Thanks!

## Purpose
**MySQL** & **Postgres** database (DB) backup.

## Prerequisite

### A. MySQL

1. Create database backup user <db-bkp-user> on the server hosting the database

connect to the server (ssh) and get into mysql prompt by using
```sh
$ mysql -u root -p
```

MySQL command
```sql
mysql> USE mysql;
mysql> CREATE USER 'db-bkp-user'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
mysql> GRANT ALL ON *.* TO 'db-bkp-user'@'localhost';
mysql> FLUSH PRIVILEGES;
```

2. Create a "linux-bkp-user" on backup server & install mysql-client on backup server
```sh
sudo adduser linux_bkp_user
sudo apt install default-mysql-client
```

3. Create a ~/.mysql-conf-file.cnf file in home dir of <linux-bkp-user> with host, user, port & password

mysql-conf-file default to backup.conf file when renamed. If not, it will be the HOST_IP

For info, it is currently [not possible to use config-editor with mysql-client](https://mariadb.com/kb/en/mysql_config_editor-compatibility/)

```conf
[mysqlpump] 
host='<db-host>' 
port='<db-port>' 
socket='<db-socket>' 
user='<db-bkp-user>' 
password='<db-bkp-password>'
```

5. Ensure that port 3306 is open on DB server

### B. Postgres

1. DB backup user on the server hosting the database

PSQL command
```sql
psql> CREATE USER 'db-bkp-user' PASSWORD 'P@ssW0rd';
psql> GRANT CONNECT ON DATABASE mydb TO 'db-bkp-user';
psql> GRANT SELECT ON ALL TABLES IN SCHEMA mySchema TO 'db-bkp-user';
```

2. Ensure that pg_hba.conf of DB server is configured to accept remote connect from Backup server (ip ex: 10.10.10.8/32)

/etc/postgres/vnr/main/pg_hba.conf
```conf
TYPE	DATABASE 	USER    ADRESS	            METHOD
host    all         all     10.10.10.8/32    md5
```

3. Add .pgpass file in home dir of specific linux user (linux_backup_user) of backup server
/home/linux_backup_user/.pgpass
```conf
10.10.10.8:5432:*:db-bkp-user:P@ssW0rd
```

4. Install postgres client on backup server
```sh
sudo apt install postgresql-client 
```

5. Ensure that port 5432 is open on DB server

## Install
Connect to your backup server and clone the repository where you want. Be aware that the user running the main backup script must have write access on *backup dir* and *db-backup dir*

    cd /path-to-db-backup
    git clone git@gitrural.cra.wallonie.be:crawapps/db-backup.git
    

## Run
Copy `backup.conf.sample` and rename it with `.conf` extension and a name based on DB host server to backup, like: *php-prod.conf, pg-test.conf, myconfig.conf*
```sh
cp backup.conf.sample myconfig.conf
```

Launch `main.sh` with -c option followed by the conf file name

    ./path-to-db-backup/main.sh -c myconfig.conf

Without -c parameter, `main.sh` reads `backup.conf` file as default.

## Notes
1. MySQL backup

If MYSQL_WHEN_DB_UPD variable is set to "YES", the list of DB to backup is prefetched based on last modification date of databases.

If anything else is set into MYSQL_WHEN_DB_UPD variable, the whole list of available database will be backed up except if you filled in the DB_LIST variable.

```sql
SELECT CONCAT(table_schema,';',date_format(max(update_time),'%Y-%m-%d')) as COLNAME \
FROM information_schema.tables WHERE table_schema IN $DBS GROUP BY table_schema;
```
Data collected for DB backup is stored in files in `mysql_bkp_work/` folder. Cfr. script `./scripts/mysql_functions.sh`

2. Postgres backup

The whole list of DB is always backed up no matter if it has been modified or not.

```sql
SELECT datname FROM pg_database WHERE not datistemplate AND datname != 'postgres' AND datname !~ 'tmp_*'
```
Cfr. script `./scripts/pgsql_backup.sh`

## Cron automation
    crontab -e
    33 12 * * * /path-to-db-backup/main.sh -c /path-to-db-backup/myconfig.config

Access and backup different DB by creating different *conf files* and *cron jobs*.

## Uninstall
Delete the folder containing the scripts

    rm -rf /path-to-db-backup
    
