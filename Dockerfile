FROM nickbreen/cron:v1.0.0

MAINTAINER Nick Breen <nick@foobar.net.nz>
MAINTAINER Daisuke Baba

RUN apt-get -qqy update && \
  DEBIAN_FRONTEND=noninteractive apt-get -qqy install mysql-client apache2-utils python-dev python-pip && \
  apt-get -qqy clean && \
  pip install s3cmd python-openstackclient python-swiftclient

ENV DBS="" MYSQL_HOST="mysql" STORAGE_TYPE="local" PREFIX="" DAILY_CLEANUP="0" MAX_DAILY_BACKUP_FILES="7"
ENV ACCESS_KEY="" SECRET_KEY="" BUCKET="" REGION="us-east-1"
ENV OS_TENANT_NAME="" OS_USERNAME="" OS_PASSWORD="" CONTAINER="" OS_AUTH_URL=""
ENV BACKUP_DIR=""

ENV CRON_D_BACKUP="0 1,9,17    * * * root   /backup.sh | logger"

COPY backup.sh restore.sh /
COPY rc.local /etc/rc.local

COPY cleanup_daily.sh /etc/cron.daily/cleanup

COPY _list.sh /_list.sh
COPY _delete.sh /_delete.sh
COPY _validate.sh /_validate.sh
