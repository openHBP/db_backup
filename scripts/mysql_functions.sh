#!/bin/bash
function is_mysql_ready() {
    mysql --login-path=$MYSQL_LOGIN_PATH 'information_schema' -e STATUS > /dev/null
	CONN_ERROR=$?
	return $CONN_ERROR
}

function get_db2bkp_upd()
{
    # DB_FILE cleaning
    # if dbmodif.new file exist rename dbmodif.new => dbmodif.old else create empty dbmodif.old
    [[ -r $DB_MODIF_NEW_FILE ]] && mv $DB_MODIF_NEW_FILE $DB_MODIF_OLD_FILE || touch $DB_MODIF_OLD_FILE
    [[ -r $DB_LIST_FILE ]] && rm $DB_LIST_FILE
    [[ -r ${DB_MODIF_NEW_FILE}.sorted ]] && rm ${DB_MODIF_NEW_FILE}.sorted
    [[ -r ${DB_MODIF_OLD_FILE}.sorted ]] && rm ${DB_MODIF_OLD_FILE}.sorted

    # Query1 information_schema.schemata to get DB list to backup based on DB_LIST & DB_INCLUDE vars
    QUERY1="SELECT schema_name FROM information_schema.schemata \
        WHERE schema_name NOT IN ('information_schema','performance_schema','mysql','sys')"
    if [[ ! -z ${DB_LIST} ]]; then
        QUERY1="${QUERY1} AND schema_name $DB_LIST_OK"
    fi
    QUERY1="${QUERY1} ORDER BY schema_name;"

    CMDLINE1="mysql --login-path=$MYSQL_LOGIN_PATH -e \"$QUERY1\""
    eval $CMDLINE1 | grep -v 'SCHEMA_NAME' >> $DB_LIST_FILE
    
    # Loop over DB_LIST_FILE from QUERY1 and build a list
    while read LINE; do
        DBS="$DBS'$LINE',"
    done < $DB_LIST_FILE
    DBS="(${DBS::-1})"

    # Query2 information_schema.tables to get last mofification date on each databases
    QUERY2="SELECT CONCAT(table_schema,';',date_format(max(update_time),'%Y-%m-%d')) as COLNAME \
        FROM information_schema.tables WHERE table_schema IN $DBS GROUP BY table_schema;"       

    CMDLINE2="mysql --login-path=$MYSQL_LOGIN_PATH -e \"$QUERY2\""
    eval $CMDLINE2 | grep -v 'COLNAME' | grep -v 'NULL' >> $DB_MODIF_NEW_FILE
    
    # Sort file before using 'comm' compare command
    sort <$DB_MODIF_OLD_FILE> ${DB_MODIF_OLD_FILE}.sorted
    sort <$DB_MODIF_NEW_FILE> ${DB_MODIF_NEW_FILE}.sorted
    # Compare file and output changes => DB TO BACKUP
    comm -13 ${DB_MODIF_OLD_FILE}.sorted ${DB_MODIF_NEW_FILE}.sorted > $DB2BKP_FILE

    # Loop over DB2BKP_FILE from QUERY2 and build a list of DB separated by space
    while read LINE; do
        DB=${LINE%;*}
        DBDATE=${LINE#*;}
        DB2BKP="${DB2BKP}${DB} "
        DB_NBR=$(($DB_NBR + 1))
    done < $DB2BKP_FILE

    DB2BKP_LIST="${DB2BKP::-1}"
    return 0
}

function get_db2bkp()
{
    rm $DB_LIST_FILE
    # Query1 information_schema.schemata to get DB list to backup based on DB_LIST & DB_INCLUDE vars
    QUERY1="SELECT schema_name FROM information_schema.schemata \
        WHERE schema_name NOT IN ('information_schema','performance_schema','mysql','sys')"
    if [[ ! -z ${DB_LIST} ]]; then
        QUERY1="${QUERY1} AND schema_name $DB_LIST_OK"
    fi
    QUERY1="${QUERY1} ORDER BY schema_name;"

    CMDLINE1="mysql --login-path=$MYSQL_LOGIN_PATH -e \"$QUERY1\""
    eval $CMDLINE1 | grep -v 'SCHEMA_NAME' >> $DB_LIST_FILE
    
    while read LINE; do
        DB=${LINE}
        DB2BKP="${DB2BKP}${DB} "
        DB_NBR=$(($DB_NBR + 1))
    done < $DB_LIST_FILE
    
    DB2BKP_LIST="${DB2BKP::-1}"
    return 0
}

function mysql_full_backup()
# All fetched DBS are backup up into one single file
# not used here
{
    BACKUP_FILE="${BACKUP_DIR}/mysql-full-`date +\%Y-\%m-\%d`"
    # Store DB location in LOG file
    echo "`date +\%Y-\%m-\%d` ($DB_NBR BKP in $BACKUP_FILE): $DB2BKP_LIST" >> $MYSQL_BKP_INFO

    CMDLINE="mysqlpump --login-path=$MYSQL_LOGIN_PATH --databases "$DB2BKP_LIST" | sed -E 's/DEFINER=[^ *]+/DEFINER=CURRENT_USER/g' | gzip > $BACKUP_FILE.sql.gz.in_progress"
    eval $CMDLINE

    if [ $? -eq 0 ]; then
        mv $BACKUP_FILE.sql.gz.in_progress $BACKUP_FILE.sql.gz
        echo -e "[SUCCESS] FULL BACKUP Done!\n"
    else
        echo -e "[ERROR] FULL BACKUP Fail!\n" 1>&2
    fi 
}

function mysql_backup()
{
    DB=$1
    BACKUP_FILE=$2
    
    echo "`date +\%Y-\%m-\%d` ($DB BKP in $BACKUP_FILE)" >> $MYSQL_BKP_INFO
    echo "--- $DB ---"
    echo "$DB BACKUP Running..."
    echo "*** $BACKUP_FILE ***"

    CMDLINE="mysqlpump --defaults-file=~/.${MYSQL_CONF_FILE}.cnf ${DB} | sed -E 's/DEFINER=[^ *]+/DEFINER=CURRENT_USER/g' | gzip > $BACKUP_FILE.sql.gz.in_progress"
    # CMDLINE="mysqlpump ${DB} | sed -E 's/DEFINER=[^ *]+/DEFINER=CURRENT_USER/g' | gzip > $BACKUP_FILE.sql.gz.in_progress"
    eval $CMDLINE

    if (( $? < 2 )); then
        mv $BACKUP_FILE.sql.gz.in_progress $BACKUP_FILE.sql.gz
        echo -e "[SUCCESS] $DB BACKUP Done!\n"
    else
        echo -e "[ERROR] $DB BACKUP Fail!\n" 1>&2
    fi 
}
