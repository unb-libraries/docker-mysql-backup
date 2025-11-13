# unblibraries/docker-mysql-backup 
Performs periodic backups of a MySQL database and rotates them using rsnapshot.

## Usage
Run the container with an argument to specify the backup type you are performing. The available arguments are:

* `hourly`: Performs an hourly backup.
* `daily`: Performs a daily backup.
* `weekly`: Performs a weekly backup.
* `monthly`: Performs a monthly backup.

These arguments are simply labels passed to the `rsnapshot` command, which will handle the actual backup rotation based on the configuration set in ENV variables (below).

## Examples

### Single Database Backup (Legacy Mode)
```bash
docker run --rm \
  -e MYSQL_HOSTNAME=mysql-host \
  -e MYSQL_PORT=3306 \
  -e MYSQL_USER_NAME=root \
  -e MYSQL_USER_PASSWORD=password \
  -e MYSQL_DATABASE=mydb \
  -e MYSQL_STRUCT_TABLES="cache_*,sessions" \
  -v /path/to/backup:/data \
  mysql-backup hourly
```
Result: Creates `/data/hourly.0/mysql/mydb.gz`

### Multiple Databases (Explicit List)
```bash
docker run --rm \
  -e MYSQL_HOSTNAME=mysql-host \
  -e MYSQL_DATABASES="app1,app2,app3" \
  -e MYSQL_USER_NAME=root \
  -e MYSQL_USER_PASSWORD=password \
  -v /path/to/backup:/data \
  mysql-backup daily
```
Result: Creates `/data/daily.0/mysql/app1.gz`, `/data/daily.0/mysql/app2.gz`, `/data/daily.0/mysql/app3.gz`

### Auto-Discovery (All Databases)
```bash
docker run --rm \
  -e MYSQL_HOSTNAME=mysql-host \
  -e MYSQL_BACKUP_ALL_DATABASES=true \
  -e MYSQL_USER_NAME=root \
  -e MYSQL_USER_PASSWORD=password \
  -v /path/to/backup:/data \
  mysql-backup weekly
```
Result: Automatically discovers all databases (excluding system databases) and creates one `.gz` file per database.

### Per-Database Structure-Only Tables
```bash
docker run --rm \
  -e MYSQL_HOSTNAME=mysql-host \
  -e MYSQL_DATABASES="drupal,wordpress" \
  -e MYSQL_STRUCT_TABLES_DRUPAL="cache_*,sessions,watchdog" \
  -e MYSQL_STRUCT_TABLES_WORDPRESS="wp_commentmeta,wp_comments" \
  -e MYSQL_USER_NAME=root \
  -e MYSQL_USER_PASSWORD=password \
  -v /path/to/backup:/data \
  mysql-backup hourly
```
Result: Each database uses its own structure-only table configuration.

## Configuration

Configure the following environment variables:

### General
- `GZIP_COMPRESSION_LEVEL`: The level of gzip compression to use for the backup files (default is 6).
- `MYSQL_DUMP_LOCATION`: The directory where the backup files will be stored (default is `/data`).

### MySQL Connection
- `MYSQL_HOSTNAME`: The hostname of the MySQL server (default is `localhost`).
- `MYSQL_PORT`: The port number of the MySQL server (default is `3306`).
- `MYSQL_USER_NAME`: The username to use for connecting to the MySQL server (default is `root`).
- `MYSQL_USER_PASSWORD`: The password to use for connecting to the MySQL server (default is `changeme`).

### Database Selection (choose one mode)

#### Mode 1: Single Database (Legacy)
- `MYSQL_DATABASE`: Backup a single specific database. This is the original behavior and is maintained for backward compatibility.

#### Mode 2: Multiple Databases (Explicit List)
- `MYSQL_DATABASES`: A comma-separated list of databases to backup (e.g., `db1,db2,db3`). Each database will be backed up to a separate `.gz` file.

#### Mode 3: Auto-Discovery
- `MYSQL_BACKUP_ALL_DATABASES`: Set to `true` or `1` to automatically discover and backup all databases on the server.
- `MYSQL_EXCLUDE_DATABASES`: Comma-separated list of databases to exclude from auto-discovery (default is `information_schema,performance_schema,mysql,sys`).

**Priority:** If multiple modes are configured, the script uses this priority order:
1. `MYSQL_DATABASE` (single database) - highest priority
2. `MYSQL_DATABASES` (explicit list)
3. `MYSQL_BACKUP_ALL_DATABASES` (auto-discovery) - lowest priority

### Structure-Only Tables

#### Global Configuration
- `MYSQL_STRUCT_TABLES`: A comma-separated list of table patterns whose data will not be included in the backup, only their structure (default is none). Supports wildcards using `*` (e.g., `cache_*,sessions`).

#### Per-Database Configuration
For multi-database backups, you can specify structure-only tables per database using environment variables in the format `MYSQL_STRUCT_TABLES_<NORMALIZED_DB_NAME>`, where the database name is uppercased and special characters (`-`, `.`) are replaced with underscores (`_`).

Examples:
- Database `myapp` → `MYSQL_STRUCT_TABLES_MYAPP=cache_%,sessions`
- Database `my-app` → `MYSQL_STRUCT_TABLES_MY_APP=cache_%,sessions`
- Database `my.app` → `MYSQL_STRUCT_TABLES_MY_APP=cache_%,sessions`

If no per-database configuration is found, the global `MYSQL_STRUCT_TABLES` value is used as a fallback.

### Rsnapshot
- `RSNAPSHOT_RETAIN_HOURLY`: The number of hourly backups to retain (default is 8).
- `RSNAPSHOT_RETAIN_DAILY`: The number of daily backups to retain (default is 7).
- `RSNAPSHOT_RETAIN_WEEKLY`: The number of weekly backups to retain (default is 4).
- `RSNAPSHOT_RETAIN_MONTHLY`: The number of monthly backups to retain (default is 6).

## License
This application was created at [![UNB Libraries](https://github.com/unb-libraries/assets/raw/master/unblibbadge.png "UNB Libraries")](https://lib.unb.ca).
- As part of our 'open' ethos, UNB Libraries licenses its applications and workflows to be freely available to all whenever possible.
- Consequently, the contents of this repository [unb-libraries/docker-mysql-backup] are licensed under the [MIT License](http://opensource.org/licenses/mit-license.html). This license explicitly excludes:
  - Any website content, which remains the exclusive property of its author(s).
  - The UNB logo and any of the associated suite of visual identity assets, which remains the exclusive property of the University of New Brunswick.
