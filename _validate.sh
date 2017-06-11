#!/bin/bash

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
  gcs)
    if [ -z "$BOTO_PATH" ] || [ -z "$GC_BUCKET" ]; then
      echo "[$STORAGE_TYPE] Cannot access to gcs with the given information"
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
