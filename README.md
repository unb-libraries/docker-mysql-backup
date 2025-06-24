# unblibraries/docker-mysql-backup 
Performs periodic backups of a MySQL database and rotates them using rsnapshot.

## Usage
Run the container with an argument to specify the backup type you are performing. The available arguments are:

* `hourly`: Performs an hourly backup.
* `daily`: Performs a daily backup.
* `weekly`: Performs a weekly backup.
* `monthly`: Performs a monthly backup.

These arguments are simply labels passed to the `rsnapshot` command, which will handle the actual backup rotation based on the configuration set in ENV variables (below).

Configure the following environment variables:

### General
- `GZIP_COMPRESSION_LEVEL`: The level of gzip compression to use for the backup files (default is 6).
- `MYSQL_DUMP_LOCATION`: The directory where the backup files will be stored (default is `/data`).

### MySQL
- `MYSQL_HOSTNAME`: The hostname of the MySQL server (default is `localhost`).
- `MYSQL_PORT`: The port number of the MySQL server (default is `3306`).
- `MYSQL_STRUCT_TABLES`: A comma-separated list of tables whose data will not be included in the backup, only their structure. (default is none).
- ` MYSQL_USER_NAME`: The username to use for connecting to the MySQL server (default is `root`).
- `MYSQL_USER_PASSWORD`: The password to use for connecting to the MySQL server (default is `changeme`).

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
