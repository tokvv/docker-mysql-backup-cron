#!/bin/bash

. /_list.sh

function delete {
  case $STORAGE_TYPE in
    s3)
      s3cmd --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY --region=$REGION del $BUCKET/$1
      ;;
    swift)
      swift delete $CONTAINER $1
      ;;
    gcs)
      gsutil rm -f gs://$GC_BUCKET/$1
      ;;
    local)
      rm -f ${BACKUP_DIR}/$1
      ;;
  esac
}

list_backup_files

if [ -n "${LATEST_BACKUP}" ]; then
  for f in ${FILTERED_BACKUPS}
  do
    if [ ${f} != "${LATEST_BACKUP}" ]; then
      delete ${f}
    fi
  done
fi

if [ -n "${ALL_BACKUP_FILES}" ]; then
  NUM_FILES=0
  TODAY=$(date +%Y-%m-%d)
  for f in ${ALL_BACKUP_FILES}
  do
    if [ `echo ${f} | grep ${TODAY}` ]; then
      continue
    fi
    let NUM_FILES=NUM_FILES+1
    if [[ "${NUM_FILES}" -le "${MAX_DAILY_BACKUP_FILES}" ]]; then
      continue;
    fi
    delete ${f}
  done
fi
