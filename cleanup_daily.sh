#!/bin/bash

. /etc/container_environment.sh

if [ -n "${DAILY_CLEANUP}" ] && [ "${DAILY_CLEANUP}" != "0" ]; then
  . /_validate.sh
  export TS_PREFIX=$(date +%Y-%m-%d -d "1 day ago")
  if [ "$?" == "0" ]; then
    . /_delete.sh
  fi
fi
