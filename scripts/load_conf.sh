#!/bin/bash
###########################
####### LOAD CONFIG #######
###########################
CONFIG_FILE_NAME="backup.conf"

while [ $# -gt 0 ]; do
    case $1 in
        -c)
        CONFIG_FILE_PATH="$2"
        CONFIG_FILE_NAME="$2"
        shift 2
        ;; 
        *)
            ${ECHO} "Unknown Option \"$1\"" 1>&2
            exit 2;
            ;;
    esac
done

if [ -z $CONFIG_FILE_PATH ] ; then
    CONFIG_FILE_PATH="${ROOT_PATH}/${CONFIG_FILE_NAME}"
fi


echo -e "Using config file $CONFIG_FILE_PATH\n"

if [ ! -r ${CONFIG_FILE_PATH} ] ; then
    echo -e "Could not load config file from ${CONFIG_FILE_PATH}\n" 1>&2
    exit 1;
fi

source "${CONFIG_FILE_PATH}"