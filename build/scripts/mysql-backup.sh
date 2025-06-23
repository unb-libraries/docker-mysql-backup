#!/usr/bin/env sh
set -x
MYSQLDUMP=/usr/bin/mariadb-dump

# Paths for temp files
TMP_SCHEMA='/tmp/schema.sql'
TMP_DATA='/tmp/MYSQL_DATABASE'
STRUCTURE_ONLY_TABLES="MYSQL_STRUCT_TABLES"
IGNORE_TABLES_FULL_DUMP_CMD=""

# 1. Dump schema-only for structure tables
if [[ -n "$STRUCTURE_ONLY_TABLES" ]]; then
  echo "Dumping schema for structure tables..."
  $MYSQLDUMP \
    --ssl-mode=DISABLED \
    --host="MYSQL_HOSTNAME" \
    --port="MYSQL_PORT" \
    --user="MYSQL_USER_NAME" \
    --password="MYSQL_USER_PASSWORD" \
    --no-data \
    --databases MYSQL_DATABASE
    "$DB_NAME"  \
    --tables $STRUCTURE_ONLY_TABLES \
    > "$TMP_SCHEMA"
    echo "✅ Dumped schema for structure tables to: $TMP_SCHEMA"

    # Prepare ignore tables command for full dump
    IGNORE_TABLES_FULL_DUMP_CMD=$(echo "$STRUCTURE_ONLY_TABLES" | sed 's/,/ --ignore-table=MYSQL_DATABASE./g' | sed 's/^/--ignore-table=MYSQL_DATABASE./')
    TMP_DATA='/tmp/data.sql'
fi


# 2. Dump full DB
echo "Dumping full database..."
$MYSQLDUMP \
  --ssl-mode=DISABLED \
  --host="MYSQL_HOSTNAME" \
  --port="MYSQL_PORT" \
  --user="MYSQL_USER_NAME" \
  --password="MYSQL_USER_PASSWORD" \
  --single-transaction \
  --quick \
  --skip-lock-tables \
  $IGNORE_TABLES_FULL_DUMP_CMD \
  "$DB_NAME" > "$TMP_DATA"
echo "✅ Dumped full database to: $TMP_DATA"


# 3. Combine schema and data dumps if structure-only tables are specified
if [[ -n "$STRUCTURE_ONLY_TABLES" ]]; then
  echo "Combining schema and data dumps..."
  cat "$TMP_SCHEMA" "$TMP_DATA" > "/tmp/MYSQL_DATABASE"
fi

# 4. Compress the final dump
gzip -"$GZIP_COMPRESSION_LEVEL" "/tmp/MYSQL_DATABASE"

# 5. Move to final location
mv "/tmp/MYSQL_DATABASE.gz" "./MYSQL_DATABASE.gz"
