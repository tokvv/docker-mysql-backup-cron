#!/bin/bash

# Generate a (gzipped) dumpfile for each database specified in ${DBS}.
# Upload to the given type of storage

. /etc/container_environment.sh

# Bailout if any command fails
set -e

. /_validate.sh

# Specify mysql host (mysql by default)
MYSQL_HOST=${MYSQL_HOST:-mysql}
MYSQL_ROOT_PASSWORD=${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD}}
MYSQLDUMP_OPTIONS=${MYSQLDUMP_OPTIONS:-"--single-transaction=true"}

# Create a temporary directory to hold the backup files.
DIR=$(mktemp -d)

# Generate a timestamp to name the backup files with.
TS=$(date +%Y-%m-%d-%H%M%S)

# Backup all databases, unless a list of databases has been specified
if [ -z "$DBS" ]
then
  # Backup all DB's in bulk
  mysqldump -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_HOST --add-drop-database --all-databases $MYSQLDUMP_OPTIONS | gzip > $DIR/${PREFIX}all-databases-$TS.sql.gz
else
  # Backup each DB separately
  for DB in $DBS
  do
    mysqldump -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_HOST --add-drop-database -B $DB $MYSQLDUMP_OPTIONS | gzip > $DIR/$PREFIX$DB-$TS.sql.gz
  done
fi

case $STORAGE_TYPE in
  s3)
    # Upload the backups to S3 --region=$REGION
    s3cmd --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY --region=$REGION sync $DIR/ $BUCKET
    ;;
  swift)
    # Upload the backups to Swift
    cd $DIR
    for f in `ls *.sql.gz`
    do
      # Avoid Authorization Failure error
      swift upload $CONTAINER ${f}
    done
    ;;
  local)
    # move the backup files in the temp directory to the backup directory
    mv $DIR/* $BACKUP_DIR/
    ;;
esac

# Clean up
rm -rf $DIR
