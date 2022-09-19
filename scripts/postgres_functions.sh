#!/bin/bash
function is_postgres_ready() {
    pg_isready -q -h $HOSTIP -p $PORT
    # (pg_isready -q -h $HOSTIP && exit 0) || exit 1
}

function role_backup()
{
    BACKUP_FILE="${BACKUP_DIR}/role-${PG_BKP_TYPE}${PERIOD}-`date +\%Y-\%m-\%d`" 
    if ! pg_dumpall -g -h "$HOSTIP" -p "$PORT" -U "$DB_BKP_USER" | gzip > $BACKUP_FILE.sql.gz.in_progress; then
        echo -e "ROLE BACKUP Fail!\n" 1>&2
    else
        mv $BACKUP_FILE.sql.gz.in_progress $BACKUP_FILE.sql.gz
        echo -e "ROLE BACKUP Done!\n"
    fi
}

function pg_backup()
{
    DB=$1
    BACKUP_FILE=$2
    ARG3=$3

    if [ $PG_BKP_TYPE = "CUSTOM" ]; then
        cmd_dump="pg_dump -Fc -h ${HOSTIP} -p ${PORT} -U ${DB_BKP_USER} -T 'tmp_*' ${ARG3} ${DB} | gzip > ${BACKUP_FILE}.sql.gz.in_progress;"
    fi
    if [ $PG_BKP_TYPE = "PLAIN" ]; then
        cmd_dump="pg_dump -Fp -h ${HOSTIP} -p ${PORT} -U ${DB_BKP_USER} -T 'tmp_*' ${ARG3} ${DB} | gzip > ${BACKUP_FILE}.sql.gz.in_progress;"
    fi    
    
    echo -e "$DB BACKUP Running..."

    if ! $(eval $cmd_dump); then
        echo -e "[ERROR] $DB BACKUP Fail!\n" 1>&2
    else
        mv $BACKUP_FILE.sql.gz.in_progress $BACKUP_FILE.sql.gz
        echo -e "[SUCCESS] $DB BACKUP Done!\n"
    fi
}
