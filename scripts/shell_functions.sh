#!/bin/bash
##########################
# display_time
# STATUS: START or END
##########################
function display_time()
{
    STATUS=$1
    if [ $STATUS = "START" ]; then
        STARTING_TIME=$(date +%s)
        echo -e "*****************************************"
        echo -e "Starting @ $(date +'%d-%m-%Y - %H:%M:%S')\n"
    fi

    if [ $STATUS = "END" ]; then
        echo -e "Ending @ $(date +'%d-%m-%Y - %H:%M:%S')\n"

        ENDING_TIME=$(date +%s)

        ELAPSED_SEC=$(($ENDING_TIME - $STARTING_TIME))

        if [ ${ELAPSED_SEC} > 60 ]; then
            ELAPSED_MIN=$(($ELAPSED_SEC / 60))
            NBRSECMIN=$(($ELAPSED_MIN*60))
            ELAPSED_SEC=$(($ELAPSED_SEC-$NBRSECMIN))
        else
            ELAPSED_MIN=0
        fi
        echo -e "Elapsed time: $ELAPSED_MIN minute(s) and $ELAPSED_SEC seconds"
        echo -e "*****************************************\n"  
    fi
}

function create_dir()
{
    DIR_NAME=$1
    
    if mkdir -p $DIR_NAME; then
        echo -e "Create directory $DIR_NAME\n"
    else
        echo -e "Cannot create directory $DIR_NAME. Go and fix it!\n" 1>&2
        exit 1;    
    fi
}

function get_period_clean_files()
{
    # MONTHLY BACKUPS
    DAY_OF_MONTH=`date +%d`
    
    if [ $DAY_OF_MONTH -eq 1 ];
    then
        # Delete all expired monthly directories
        find $BACKUP_DIR -maxdepth 1 -name "*-monthly" -exec rm -rf '{}' ';'
        PERIOD="-monthly"
    else
        # WEEKLY BACKUPS
        DAY_OF_WEEK=`date +%u` #1-7 (Monday-Sunday)
        EXPIRED_DAYS=`expr $((($WEEKS_TO_KEEP * 7) + 1))`
        
        if [ $DAY_OF_WEEK = $DAY_OF_WEEK_TO_KEEP ];
        then
            # Delete all expired weekly directories
            find $BACKUP_DIR -maxdepth 1 -mtime +$EXPIRED_DAYS -name "*-weekly" -exec rm -rf '{}' ';'
            PERIOD="-weekly"
            
        else
            # DAILY BACKUPS
            # Delete daily backups 7 days old or more
            find $BACKUP_DIR -maxdepth 1 -mtime +$DAYS_TO_KEEP -name "*-daily" -exec rm -rf '{}' ';'
            PERIOD="-daily"
        fi

    fi
}