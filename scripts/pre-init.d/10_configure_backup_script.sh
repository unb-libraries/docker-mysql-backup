#!/usr/bin/env sh
sed -i "s|MYSQL_HOSTNAME|$MYSQL_HOSTNAME|g" /scripts/mysql-backup.sh
sed -i "s|MYSQL_PORT|$MYSQL_PORT|g" /scripts/mysql-backup.sh
sed -i "s|MYSQL_USER_NAME|$MYSQL_USER_NAME|g" /scripts/mysql-backup.sh
sed -i "s|MYSQL_USER_PASSWORD|$MYSQL_USER_PASSWORD|g" /scripts/mysql-backup.sh
sed -i "s|MYSQL_DATABASE|$MYSQL_DATABASE|g" /scripts/mysql-backup.sh
