#!/bin/bash

# Generate a (gzipped) dumpfile for each database specified in ${DBS}.
# Upload to the given type of storage

. /etc/container_environment.sh

# Bailout if any command fails
set -e

case $STORAGE_TYPE in
	s3)
		if [ -z "$ACCESS_KEY" ] || [ -z "$SECRET_KEY" ] || [ -z "$BUCKET" ]; then
			echo "[$STORAGE_TYPE] Cannot access to s3 with the given information"
			exit 1
		fi
		;;
  swift)
		if [ -z "$OS_TENANT_NAME" ] || [ -z "$OS_USERNAME" ] || [ -z "$OS_PASSWORD" ] || [ -z "$CONTAINER" ] || [ -z "$OS_AUTH_URL" ]; then
			echo "[$STORAGE_TYPE] Cannot access to swift with the given information"
			exit 1
		fi
		;;
	local)
		if [ ! -d "$BACKUP_DIR" ]; then
			echo "[$STORAGE_TYPE] Cannot backup to the missing directory"
			exit 1
		fi
		;;
	*)
		echo "Unknown storage type => $STORAGE_TYPE. s3, swift or local is valid."
		exit 1
		;;
esac


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
	mysqldump -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_HOST --all-databases $MYSQLDUMP_OPTIONS | gzip > $DIR/${PREFIX}all-databases-$TS.sql.gz
else
	# Backup each DB separately
	for DB in $DBS
	do
		mysqldump -uroot -p$MYSQL_ROOT_PASSWORD -h$MYSQL_HOST -B $DB $MYSQLDUMP_OPTIONS | gzip > $DIR/$PREFIX$DB-$TS.sql.gz
	done
fi

case $STORAGE_TYPE in
	s3)
		# Upload the backups to S3 --region=$REGION
		s3cmd --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY --region=$REGION sync $DIR/ $BUCKET
		;;
  swift)
		# Upload the backups to Swift
		swift upload $CONTAINER $DIR/
		;;
	local)
	  # move the backup files in the temp directory to the backup directory
		mv $DIR/* $BACKUP_DIR/
		;;
esac

# Clean up
rm -rf $DIR
