#!/usr/bin/env sh
set -x
MYSQLDUMP=/usr/bin/mysqldump
$MYSQLDUMP -h MYSQL_HOSTNAME -P MYSQL_PORT --force --events --ignore-table=mysql.event --opt --user=MYSQL_USER_NAME -pMYSQL_USER_PASSWORD --databases MYSQL_DATABASE > "/tmp/MYSQL_DATABASE"
gzip -9 "/tmp/MYSQL_DATABASE"
mv "/tmp/MYSQL_DATABASE.gz" "./MYSQL_DATABASE.gz"
