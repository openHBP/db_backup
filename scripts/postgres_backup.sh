#!/bin/bash
source "${SCRIPTS_PATH}/postgres_functions.sh"


# 1. Check if Postgres is Ready
is_postgres_ready || {
    echo -e "Remote host $HOSTIP:$PORT reject Postgres connection\n" 1>&2
    exit 2;
}

# 2. Create backup directory
create_dir $BACKUP_DIR

# 2.1 get period + file cleanup (daily, weekly, monthly)
get_period_clean_files

# 3. Call role backup
role_backup

# 4. Build Backup query
BKP_QUERY="SELECT datname FROM pg_database WHERE not datistemplate AND datname != 'postgres' AND datname !~ 'tmp_*'"

if [[ ! -z "${DB_LIST_SPEC_OK}" ]]; then
    BKP_QUERY="${BKP_QUERY} AND datname NOT IN ($DB_LIST_SPEC_OK)"
fi

if [[ ! -z ${DB_LIST} ]]; then
    BKP_QUERY="${BKP_QUERY} AND datname ${DB_LIST_OK}"
fi

BKP_QUERY="${BKP_QUERY} ORDER BY datname;"


# 5. Run Backup against each databases fetched by BKP_QUERY
echo -e "*** BACKUP START ***"
#echo -e "BKP_QUERY: $BKP_QUERY\n"

for DB in `psql -h "$HOSTIP" -p "$PORT" -U "$DB_BKP_USER" -At -c "$BKP_QUERY" postgres`
do
    BACKUP_DB_DIR="${BACKUP_DIR}/${DB}/"
    create_dir $BACKUP_DB_DIR
    # name example: visa_prod-weekly-2022-09-11.sql.gz
    BACKUP_FILE="${BACKUP_DB_DIR}${DB}-${PG_BKP_TYPE}${PERIOD}-`date +\%Y-\%m-\%d`"

    # Check if DB is in DB_LIST_SPEC
    if echo $DB_LIST_SPEC | grep -w $DB > /dev/null; then
        # Specific backups call
        source "${SCRIPTS_PATH}/${DB}.sh"
    else
        # Normal backup call
        pg_backup $DB $BACKUP_FILE ""
    fi

done
echo -e "*** BACKUP END ***"
