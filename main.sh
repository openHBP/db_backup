#!/bin/bash
ROOT_PATH=$(cd ${0%/*} && pwd -P)
SCRIPTS_PATH="${ROOT_PATH}/scripts"

# Load config file
source "${SCRIPTS_PATH}/load_conf.sh"

# Load default vars
source "${SCRIPTS_PATH}/load_defaults.sh"

# Load shell functions
source "${SCRIPTS_PATH}/shell_functions.sh"

# Call display_time with STATUS=START
display_time "START"

if [ $DB_TYPE = "MYSQL" ]; then
    source "${SCRIPTS_PATH}/mysql_backup.sh"
fi
# run postgres backup
if [ $DB_TYPE = "POSTGRES" ]; then
    source "${SCRIPTS_PATH}/postgres_backup.sh"
fi

# Call display_time with STATUS=END
display_time "END"
