#!/bin/bash
# Backup partitioned tables in a separate folder
MP_PRT_BACKUP_DIR=${BACKUP_DB_DIR}"0000-mp_partitioned/"
create_dir $MP_PRT_BACKUP_DIR

TABLE_LIST="geomatique_cleandatawal geomatique_forecastsirm"


for TABLE in $TABLE_LIST
do
    # Prepare the list of excluded tables for backup of meteo_paille (done below)
    EXCL_TBL="${EXCL_TBL} --exclude-table-data='${TABLE}*'"
    
    # Backup all the partitioned tables for the last nb of months
    for (( i=0; i<3; i++ ))
    do
        YEAR=`date -d "$(date +%Y-%m-1) -$i month" +%Y`
        MTH=`date -d "$(date +%Y-%m-1) -$i month" +%m`

        echo -e "$DB - '${TABLE}_y${YEAR}m${MTH}' BACKUP Running..."

        cmd_dump="pg_dump -Fp -h ${HOSTIP} -p ${PORT} -U ${DB_BKP_USER} --table=${TABLE}_y${YEAR}m${MTH} ${DB} | gzip > ${MP_PRT_BACKUP_DIR}${DB}_${TABLE}_y${YEAR}m${MTH}.sql.gz.in_progress;"
        if ! $(eval $cmd_dump); then
            echo -e "[ERROR] $DB - '${TABLE}_y${YEAR}m${MTH}' Fail!\n" 1>&2
        else
            cmd_mv="mv ${MP_PRT_BACKUP_DIR}${DB}_${TABLE}_y${YEAR}m${MTH}.sql.gz.in_progress ${MP_PRT_BACKUP_DIR}${DB}_${TABLE}_y${YEAR}m${MTH}.sql.gz"
            eval $cmd_mv
            echo -e "[SUCCESS] $DB - '${TABLE}_y${YEAR}m${MTH}' Done!\n"
        fi
    done
done


# Backup meteo_paille excluding partitioned tables data and all temporary tables
pg_backup $DB $BACKUP_FILE "$EXCL_TBL"

# cmd_dump="pg_dump -Fp -h ${HOSTIP} -p ${PORT} -U ${DB_BKP_USER} -T 'tmp_*' ${EXCL_TBL} ${DB} | gzip > ${FINAL_BACKUP_DIR}${DB}.sql.gz.in_progress;"
# echo -e "$DB BACKUP Running..."

# if ! $(eval $cmd_dump); then
#     echo -e "[ERROR] $DB BACKUP Fail!\n"
# else
#     cmd_mv="mv ${FINAL_BACKUP_DIR}${DB}.sql.gz.in_progress ${FINAL_BACKUP_DIR}${DB}.sql.gz"
#     eval $cmd_mv
#     echo -e "[SUCCESS] $DB BACKUP Done!\n"
# fi
