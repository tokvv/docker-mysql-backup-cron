#!/bin/bash

# Fetch a (gzipped) backup file from S3.
# Restore it.

. /etc/container_environment.sh

# Bailout if any command fails
set -e

. /_validate.sh

# Check that a backup is specified or list all backups!
if [ -z "$1" ]
then
  case $STORAGE_TYPE in
    s3)
      BUCKET_PREFIX=$BUCKET
      if [ -n "$PREFIX" ]; then
        BUCKET_PREFIX=$BUCKET/$PREFIX
      fi
      s3cmd --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY --region=$REGION ls $BUCKET_PREFIX | grep .sql.gz
      ;;
    swift)
      FILE_PREFIX=""
      if [ -n "$PREFIX" ]; then
        FILE_PREFIX="--prefix ${PREFIX}"
      fi
      swift list $CONTAINER $FILE_PREFIX | grep .sql.gz
      ;;
    local)
      cd ${BACKUP_DIR}
      find . -type f -name "*.sql.gz" | grep "^./${PREFIX}"
      ;;
  esac

else
  # Create a temporary directory to hold the backup files
  find /tmp -type d | grep -v "^/tmp$" | xargs rm -fr
  DIR=$(mktemp -d)
  FILE_NAME=`basename $1`

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

  # Specify mysql host (mysql by default)
  MYSQL_HOST=${MYSQL_HOST:-mysql}
  MYSQL_ROOT_PASSWORD=${MYSQL_ENV_MYSQL_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD}}

  # Restore the DB
  gunzip < $DIR/$FILE_NAME | mysql -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_HOST

  # Clean up
  rm -rf $DIR
fi
