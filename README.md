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

## Google Cloud Storage (`gcs`)

The following environment variables must be provided.

- `BOTO_PATH`
- `GC_BUCKET` ... must point to the path to BOTO file (container)

## Local File System (`local`)

The following environment variable must be provided.

- `BACKUP_DIR`

## Example

See docker-compose.yml for an example of configuration.

# Build

    docker build -t mysql-backup-cron .

# Run

Schedule UTC 1:00 am, 9:00 am and 5:00 pm per day.

```
    docker run -tid --name mysql-backup-cron \
        --net my_network_name \
        -e MYSQL_ROOT_PASSWORD=my_root_password \
        -e MYSQL_HOST=mysql_host \
        -e BACKUP_DIR=/backup \
        -e PREFIX=subdir/here/with-prefix \
        -v $(pwd):/backup mysql-backup-cron
```

Schedule every 5 minutes.

```
    docker run -tid --name mysql-backup-cron \
        --net my_network_name \
        -e MYSQL_ROOT_PASSWORD=my_root_password \
        -e MYSQL_HOST=mysql_host \
        -e BACKUP_DIR=/backup \
        -e CRON_D_BACKUP="*/5 * * * * root /backup.sh | logger" \
        -e PREFIX=subdir/here/with-prefix \
        -v $(pwd):/backup mysql-backup-cron
```

# Exec

Use `docker exec <container> /backup.sh` to take an immediate backup.

Use `docker exec <container> /restore.sh` to list available backups to restore
from. Then `docker exec /restore.sh <filename of backup>` to
restore it. You can also run `docker exec /restore.sh __latest__` for restoring from the latest backup file.

# Backup

## File Name format

```
  2017-01-20-000252.sql.gz
  `--+`-+`-+`---+--`---+--
     |  |  |    |      +------- suffix
     |  |  |    +-------------- time
     |  |  +------------------- day
     |  +---------------------- month
     +------------------------- year
```

## Backup Cleanup Schedule and Behavior

When providing `DAILY_CLEANUP=1`, the following scheduled cleaner is enabled (disabled by default).

| Interval | Description                        |
|----------|------------------------------------|
| Daily    | Retain the latest file 1 day ago and remove the oldest files if the number of backup files exceeds `MAX_DAILY_BACKUP_FILES`. |

`MAX_DAILY_BACKUP_FILES` is used for specifying the max number of the backup files to be retained.

# Revision History
- 2.4.5
  * Fix an issue where the parent paths in the backup file path was unexpectedly removed

- 2.4.4
  * Fix an issue where ls failed to show files recursively

- 2.4.3
  * Add a subdirectory path on performing gcs backup

- 2.4.2
  * Fix sed expression error

- 2.4.1
  * Fix an issue where unexpected dir was created on GCS backup

- 2.4.0
  * Add a new storage type, `gcs`

- 2.3.1
  * Fix an issue where local restore failed to copy a file when the path contains file separators

- 2.3.0
  * Fix an issue where —events is missing
  * Add a new feature to restore from the latest backup file (exit code=1 when nothing to restore from)
  * Clean temporary directories under `/tmp`
  * Fix an issue where restore.sh failed to create subdirectories when the prefix contains file separators

- 2.2.1
  * Fix restore.sh

- 2.2.0
  * Accept '/' file separator as PREFIX

- 2.1.0
  * Add `--add-drop-database` to mysqldump

- 2.0.0
  * Add backup cleaner (disabled by default)

- 1.0.0
  * Initial Release as of the forked version of `docker-mysql-backup-cron`
