# This Image

A cron job runs every 8 hours.  Override this by setting cron job spec's in
the `CRON_D_BACKUP` environment variable.

It backups all databases, unless `DBS`
is specified as a space separated list of DB's to backup, using `mysqldump`.

By default, `MYSQLDUMP_OPTIONS` is assigned to `--single-transaction=true`. You can overwrite the option by specifying the variable.

The file are `gzip`ed. The optional `PREFIX` can be used for adding the prefix to the backup file name.

If the DB is linked to this container make sure that `MYSQL_ROOT_PASSWORD` is set in the linked mysql container.

You can use docker network to connect to the DB container with `--net` as well. If you go this way, make sure that both `MYSQL_ROOT_PASSWORD` and `MYSQL_HOST`(container name) are set in this backup container.

You can choose 3 types of backup destination, `s3` for AWS S3, `swift` for OpenStack Object Storage and `local` for local file system.

## Amazon S3 (`s3`)

You must specify an AWS access key and secret key as well as the S3 bucket and
optionally the prefix to store the backups in.

You *must* specify the bucket (and prefix) with the `s3:` scheme and trailing
slash; e.g. `s3://some-bucket/` or `s3://some-bucket/some-prefix/`.

By default, the S3 region used is `us-east-1`.
You can override it  with the REGION environment variable.
See [the official amazon region names](http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region) for more informations.

## OpenStack Swift (`swift`)

The following environment variables must be provided.

- `OS_TENANT_NAME`
- `OS_USERNAME`
- `OS_PASSWORD`
- `OS_AUTH_URL`
- `CONTAINER`

## Local Files System (`local`)

The following environment variable must be provided.

- `BACKUP_DIR`

## Example

See docker-compose.yml for an example of configuration.

# Build

    docker build -t mysql-backup-cron .

# Run

Schedule UTC 1:00 am, 9:00 am and 5:00 pm per day.

```
    docker run -ti --rm --name mysql-backup-cron \
        --net nw_name_you_created \
        -e MYSQL_ROOT_PASSWORD=root_password \
        -e MYSQL_HOST=mysql_host \
        -e BACKUP_DIR=/backup \
        -v $(pwd):/backup mysql-backup-cron
```

Schedule every 5 minutes.

```
    docker run -ti --rm --name mysql-backup-cron \
        --net nw_MYACCOUNTID \
        -e MYSQL_ROOT_PASSWORD=MYACCOUNTID_root \
        -e MYSQL_HOST=egg_MYACCOUNTID_mysql \
        -e BACKUP_DIR=/backup \
        -e CRON_D_BACKUP="*/5 * * * * root /backup.sh | logger" \
        -v $(pwd):/backup mysql-backup-cron
```

# Exec

Use `docker exec <container> /backup.sh` to take an immediate backup.

Use `docker exec <container> /restore.sh` to list available backups to restore
from. Then `docker exec /restore.sh <filename of backup>` to
restore it.

# Revision History

- 1.0.0
  * Initial Release as of the forked version of `docker-mysql-backup-cron`
