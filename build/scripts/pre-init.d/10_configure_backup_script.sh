#!/usr/bin/env sh
# Substitute connection parameters
sed -i "s|MYSQL_HOSTNAME|$MYSQL_HOSTNAME|g" /scripts/mysql-backup.sh
sed -i "s|MYSQL_PORT|$MYSQL_PORT|g" /scripts/mysql-backup.sh
sed -i "s|MYSQL_USER_NAME|$MYSQL_USER_NAME|g" /scripts/mysql-backup.sh
sed -i "s|MYSQL_USER_PASSWORD|$MYSQL_USER_PASSWORD|g" /scripts/mysql-backup.sh

# Substitute multi-database configuration (longer strings first to avoid partial matches)
sed -i "s|MYSQL_BACKUP_ALL_DATABASES|$MYSQL_BACKUP_ALL_DATABASES|g" /scripts/mysql-backup.sh
sed -i "s|MYSQL_EXCLUDE_DATABASES|$MYSQL_EXCLUDE_DATABASES|g" /scripts/mysql-backup.sh
sed -i "s|MYSQL_DATABASES|$MYSQL_DATABASES|g" /scripts/mysql-backup.sh

# Substitute single-database configuration (legacy - do this after MYSQL_DATABASES to avoid partial match)
sed -i "s|MYSQL_DATABASE|$MYSQL_DATABASE|g" /scripts/mysql-backup.sh

# Substitute structure-only tables configuration
# Use a special placeholder to avoid conflicts with MYSQL_STRUCT_TABLES_<DB_NAME> variables
sed -i "s|__GLOBAL_MYSQL_STRUCT_TABLES__|$MYSQL_STRUCT_TABLES|g" /scripts/mysql-backup.sh

# Substitute compression level
sed -i "s|GZIP_COMPRESSION_LEVEL|$GZIP_COMPRESSION_LEVEL|g" /scripts/mysql-backup.sh

# Export all MYSQL_STRUCT_TABLES_* environment variables so they're available to the backup script
# This allows per-database structure-only table configuration
export $(env | grep '^MYSQL_STRUCT_TABLES_' || true)
