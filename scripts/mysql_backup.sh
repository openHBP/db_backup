#!/bin/bash
source "${SCRIPTS_PATH}/mysql_functions.sh"

# 1. Check if MySQL is Ready
is_mysql_ready || {
    echo -e "$HOSTIP:$PORT reject mysql connection"
    echo -e "Check login-path with mysql_config_editor and associated backup_database_user grant in DB\n"
    exit 1;
}

# 2. Create backup directory
create_dir $BACKUP_DIR
DB_NBR=0

# 2.1 get period + file cleanup (daily, weekly, monthly)
get_period_clean_files

# 3. Create list of DB in variable $DB2BKP_LIST
if [ $MYSQL_WHEN_DB_UPD = "YES" ] ; then
    get_db2bkp_upd
else
    get_db2bkp
fi


echo -e "\n*******************"
echo "$DB_NBR DB BACKUP on `date +\%Y-\%m-\%d`: $DB2BKP_LIST"
echo -e "*******************\n"

# 4. Is there DB to backup?
if [[ ! -z ${DB2BKP_LIST} ]]; then
    echo -e "*** MYSQL BACKUP START ***"
    for DB in ${DB2BKP_LIST}; do
        BACKUP_DB_DIR="${BACKUP_DIR}/${DB}/"
        create_dir $BACKUP_DB_DIR
        BACKUP_FILE="${BACKUP_DB_DIR}${DB}${PERIOD}-`date +\%Y-\%m-\%d`"
        # Call mysql_backup function
        mysql_backup $DB $BACKUP_FILE
    done
    echo -e "*** MYSQL BACKUP END ***"
else
    echo -e "NOTHING TO BACKUP\n"
fi