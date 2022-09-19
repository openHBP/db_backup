#!/bin/bash
###########################
### INITIALISE DEFAULTS ###
###########################

if [ ! $EXECUTING_USER ]; then
    EXECUTING_USER=`whoami`
fi


if [ $CONFIG_FILE_NAME = "backup.conf" ]; then
    HOSTNAME=$HOSTIP
else
    HOSTNAME=$(echo "${CONFIG_FILE_PATH##*/}" | cut -d "." -f1)
fi

if [ ! $MYSQL_CONF_FILE ]; then
    MYSQL_CONF_FILE=$HOSTNAME
fi

if [ ! $PORT ]; then
    if [ $DB_TYPE = "POSTGRES" ]; then
        PORT="5432"
    fi;
    if [ $DB_TYPE = "MYSQL" ]; then
        PORT="3306"
    fi;    
fi;
 
if [ ! $DB_BKP_USER ]; then
    DB_BKP_USER=""
fi;

if [ ! $BACKUP_DIR ]; then
    BACKUP_DIR="/home/${EXECUTING_USER}/dumps/${HOSTNAME}"
fi;

if [[ ! -z ${DB_LIST} ]]; then
    DB_LIST_OK=""
    for DB in ${DB_LIST}; do
        DB_LIST_OK="${DB_LIST_OK}'${DB}',"
    done
    DB_LIST_OK=" ${DB_INCLUDE} (${DB_LIST_OK::-1})"
fi

if [[ ! -z ${DB_LIST} ]]; then
    DB_LIST_OK=""
    for DB in ${DB_LIST}; do
        DB_LIST_OK="${DB_LIST_OK} '$DB',"
    done
    DB_LIST_OK=" ${DB_INCLUDE} (${DB_LIST_OK::-1})"
fi

# DB FILES (MYSQL ONLY)
DB_FILE_DIR="$ROOT_PATH/mysql_bkp_work"
DB_LIST_FILE="$DB_FILE_DIR/${HOSTNAME}_dblist.txt"
DB_MODIF_OLD_FILE="$DB_FILE_DIR/${HOSTNAME}_dbmodif.old"
DB_MODIF_NEW_FILE="$DB_FILE_DIR/${HOSTNAME}_dbmodif.new"
DB2BKP_FILE="$DB_FILE_DIR/${HOSTNAME}_db2bkp.txt"

# Mysql backups info file: when, which database and where it has been backup up
MYSQL_BKP_INFO="${ROOT_PATH}/mysql_bkp_info/${HOSTNAME}-${PORT}.info"
