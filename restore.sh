#!/bin/bash

# Fetch a (gzipped) backup file from S3.
# Restore it.

. /etc/container_environment.sh

# Bailout if any command fails
set -e

. /_validate.sh
. /_list.sh

function restore {
  case $STORAGE_TYPE in
    s3)
      # Get the backups from S3
      s3cmd --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY --region=$REGION get $BUCKET$1 $DIR/$1
      ;;
    swift)
      swift download $CONTAINER $1 --output $DIR/$1
      ;;
    local)
      cp -f $BACKUP_DIR/$1 $DIR
      ;;
  esac
}

# Check that a backup is specified or list all backups!
if [ -z "$1" ]
then
  list_backup_files
  for f in ${ALL_BACKUP_FILES}
  do
    echo $f
  done
else
  # Create a temporary directory to hold the backup files
  find /tmp -type d | grep -v "^/tmp$" | xargs rm -fr
  DIR=$(mktemp -d)
  BACKUP_FILE_PATH=$1

  if [ "${BACKUP_FILE_PATH}" == "__latest__" ]; then
    list_backup_files
    BACKUP_FILE_PATH=${LATEST_BACKUP}
  fi

  FILE_NAME=`basename ${BACKUP_FILE_PATH}`
  restore ${BACKUP_FILE_PATH}
  echo "${BACKUP_FILE_PATH}"

  # Specify mysql host (mysql by default)
  MYSQL_HOST=${MYSQL_HOST:-mysql}
  MYSQL_ROOT_PASSWORD=${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD}}

  # Restore the DB
  gunzip < $DIR/$FILE_NAME | mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_HOST

  # Clean up
  rm -rf $DIR
fi
