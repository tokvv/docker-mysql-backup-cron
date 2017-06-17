#!/bin/bash

function list_backup_files {
  TMP_OUT="/tmp/list"
  rm -f ${TMP_OUT}
  case $STORAGE_TYPE in
    s3)
      BUCKET_PREFIX=$BUCKET
      if [ -n "$PREFIX" ]; then
        BUCKET_PREFIX=$BUCKET/$PREFIX
      fi
      s3cmd --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY --region=$REGION ls $BUCKET_PREFIX > ${TMP_OUT}
      ;;
    swift)
      CONTAINER_PREFIX=""
      if [ -n "$PREFIX" ]; then
        CONTAINER_PREFIX="--prefix ${PREFIX}"
      fi
      swift list $CONTAINER $CONTAINER_PREFIX > ${TMP_OUT}
      ;;
    gcs)
      prefix="gs://$GC_BUCKET/"
      for p in `gsutil ls -r ${prefix}${PREFIX} | grep -v ":$"`; do
        if [ -z "$p" ]; then
          continue
        fi
        p2=$(echo ${p} | sed "s/${prefix//\//\\/}//g")
        # remove gs://bucket-name/
        echo "${p2}" >> ${TMP_OUT}
      done
      ;;
    local)
      cd ${BACKUP_DIR}
      find . -type f -name "*.sql.gz" | grep "^./${PREFIX}" > ${TMP_OUT}
      ;;
  esac
  if [ -z "${TS_PREFIX}" ]; then
    LATEST_BACKUP=`cat ${TMP_OUT} | sort -r | head -1`
  else
    LATEST_BACKUP=`cat ${TMP_OUT} | grep ${TS_PREFIX} | sort -r | head -1`
  fi
  if [ -z "${TS_PREFIX}" ]; then
    FILTERED_BACKUPS=`cat ${TMP_OUT}`
  else
    FILTERED_BACKUPS=`cat ${TMP_OUT} | grep ${TS_PREFIX}`
  fi
  ALL_BACKUP_FILES=`cat ${TMP_OUT} | sort -r`
  rm -f ${TMP_OUT}
}
