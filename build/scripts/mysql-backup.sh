#!/usr/bin/env sh
set -ex
MYSQLDUMP=/usr/bin/mysqldump

# Resolves existing table names based on MySQL wildcard patterns
resolve_tables() {
  pattern="$1"  # e.g., cache_%
  mysql \
    --skip-ssl \
    --host="MYSQL_HOSTNAME" \
    --port="MYSQL_PORT" \
    --user="MYSQL_USER_NAME" \
    --password="MYSQL_USER_PASSWORD" \
    --batch --skip-column-names \
    -e "SHOW TABLES LIKE '${pattern}';" MYSQL_DATABASE
}

# Paths for temp files
TMP_SCHEMA='/tmp/schema.sql'
TMP_DATA='/tmp/MYSQL_DATABASE'
STRUCTURE_ONLY_TABLES="MYSQL_STRUCT_TABLES"
IGNORE_TABLES_FULL_DUMP_CMD=""

# 1. Dump schema-only for structure tables
if [ -n "$STRUCTURE_ONLY_TABLES" ]; then
  echo "Resolving structure-only tables..."
  STRUCTURE_ONLY_PATTERNS=$(echo "$STRUCTURE_ONLY_TABLES" | tr ',' ' ' | tr '*' '%')
  STRUCTURE_ONLY_TABLES_EXPANDED=""
  for pattern in $STRUCTURE_ONLY_PATTERNS; do
    TABLES=$(resolve_tables "$pattern")
    STRUCTURE_ONLY_TABLES_EXPANDED="$STRUCTURE_ONLY_TABLES_EXPANDED $TABLES"
  done
  # Remove leading/trailing whitespace
  STRUCTURE_ONLY_TABLES_EXPANDED=$(echo "$STRUCTURE_ONLY_TABLES_EXPANDED" | xargs)
  echo "✅ Resolved structure-only tables: [$STRUCTURE_ONLY_TABLES_EXPANDED]"

  echo "Dumping schema for structure tables..."
  $MYSQLDUMP \
    --skip-ssl \
    --host="MYSQL_HOSTNAME" \
    --port="MYSQL_PORT" \
    --user="MYSQL_USER_NAME" \
    --password="MYSQL_USER_PASSWORD" \
    --no-data \
    --databases MYSQL_DATABASE \
    --tables $STRUCTURE_ONLY_TABLES_EXPANDED > "$TMP_SCHEMA"
  echo "✅ Dumped schema for structure tables to: $TMP_SCHEMA"

  # Prepare ignore tables command for full dump
  IGNORE_TABLES_FULL_DUMP_CMD=$(echo "$STRUCTURE_ONLY_TABLES_EXPANDED" | sed 's/ / --ignore-table=MYSQL_DATABASE./g' | sed 's/^/--ignore-table=MYSQL_DATABASE./')
  echo "Prepared ignore tables command for full dump: [$IGNORE_TABLES_FULL_DUMP_CMD]"
  TMP_DATA='/tmp/data.sql'
fi

# 2. Dump full DB
echo "Dumping full database..."
$MYSQLDUMP \
  --skip-ssl \
  --host="MYSQL_HOSTNAME" \
  --port="MYSQL_PORT" \
  --user="MYSQL_USER_NAME" \
  --password="MYSQL_USER_PASSWORD" \
  --single-transaction \
  --quick \
  --skip-lock-tables \
  $IGNORE_TABLES_FULL_DUMP_CMD \
  "MYSQL_DATABASE" > "$TMP_DATA"
echo "✅ Dumped full database to: $TMP_DATA"

# 3. Combine schema and data dumps if structure-only tables are specified
if [ -n "$STRUCTURE_ONLY_TABLES" ]; then
  echo "Combining schema and data dumps..."
  cat "$TMP_SCHEMA" "$TMP_DATA" > "/tmp/MYSQL_DATABASE"
fi

# 4. Strip lines containng "enable the sandbox mode" for compatibilty with old versions
# See: https://github.com/drush-ops/drush/issues/6027
sed -i '/enable the sandbox mode/d' "/tmp/MYSQL_DATABASE"

# 5. Compress the export
echo "Compressing the export..."
gzip -GZIP_COMPRESSION_LEVEL "/tmp/MYSQL_DATABASE"

# 6. Move to final location
mv "/tmp/MYSQL_DATABASE.gz" "./MYSQL_DATABASE.gz"

# 7. Clean up temporary files
rm -f "$TMP_SCHEMA" "$TMP_DATA"

echo "✅ MySQL backup completed successfully. Export saved to: ./MYSQL_DATABASE.gz"
