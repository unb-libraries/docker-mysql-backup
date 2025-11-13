#!/usr/bin/env sh
set -e  # Exit on error (but we'll handle it explicitly)

MYSQLDUMP=/usr/bin/mariadb-dump
BACKUP_FAILED=0  # Track if any database backup failed

# Resolves existing table names based on MySQL wildcard patterns
resolve_tables() {
  database="$1"
  pattern="$2"  # e.g., cache_%
  mysql \
    --skip-ssl \
    --host="MYSQL_HOSTNAME" \
    --port="MYSQL_PORT" \
    --user="MYSQL_USER_NAME" \
    --password="MYSQL_USER_PASSWORD" \
    --batch --skip-column-names \
    -e "SHOW TABLES LIKE '${pattern}';" "$database" 2>/dev/null || true
}

# Normalize database name for environment variable lookup
# e.g., "my-db" -> "MY_DB", "my.db" -> "MY_DB"
normalize_db_name() {
  echo "$1" | tr '[:lower:]' '[:upper:]' | tr '-' '_' | tr '.' '_'
}

# Backup a single database
backup_single_database() {
  DB_NAME="$1"
  echo "=================================================="
  echo "Backing up database: $DB_NAME"
  echo "=================================================="

  # Check for database-specific structure-only tables
  # Format: MYSQL_STRUCT_TABLES_<NORMALIZED_DB_NAME>
  NORMALIZED_NAME=$(normalize_db_name "$DB_NAME")

  # Try to get per-database structure-only tables
  # Use eval to dynamically access the variable (disable -e temporarily to handle unset vars)
  STRUCTURE_ONLY_TABLES=""
  VAR_NAME="MYSQL_STRUCT_TABLES_${NORMALIZED_NAME}"
  set +e
  eval "STRUCTURE_ONLY_TABLES=\${${VAR_NAME}}" 2>/dev/null
  set -e

  # If no per-database config, fall back to global MYSQL_STRUCT_TABLES
  if [ -z "$STRUCTURE_ONLY_TABLES" ]; then
    STRUCTURE_ONLY_TABLES="__GLOBAL_MYSQL_STRUCT_TABLES__"
  fi

  # Paths for temp files
  TMP_SCHEMA="/tmp/schema_${DB_NAME}.sql"
  TMP_DATA="/tmp/data_${DB_NAME}.sql"
  TMP_COMBINED="/tmp/${DB_NAME}"
  IGNORE_TABLES_FULL_DUMP_CMD=""

  # 1. Dump schema-only for structure tables if specified
  if [ -n "$STRUCTURE_ONLY_TABLES" ]; then
    echo "Resolving structure-only tables for $DB_NAME..."
    STRUCTURE_ONLY_PATTERNS=$(echo "$STRUCTURE_ONLY_TABLES" | tr ',' ' ' | tr '*' '%')
    STRUCTURE_ONLY_TABLES_EXPANDED=""
    for pattern in $STRUCTURE_ONLY_PATTERNS; do
      TABLES=$(resolve_tables "$DB_NAME" "$pattern")
      if [ -n "$TABLES" ]; then
        STRUCTURE_ONLY_TABLES_EXPANDED="$STRUCTURE_ONLY_TABLES_EXPANDED $TABLES"
      fi
    done
    # Remove leading/trailing whitespace
    STRUCTURE_ONLY_TABLES_EXPANDED=$(echo "$STRUCTURE_ONLY_TABLES_EXPANDED" | xargs)

    if [ -n "$STRUCTURE_ONLY_TABLES_EXPANDED" ]; then
      echo "✅ Resolved structure-only tables for $DB_NAME: [$STRUCTURE_ONLY_TABLES_EXPANDED]"

      echo "Dumping schema for structure tables..."
      $MYSQLDUMP \
        --skip-ssl \
        --host="MYSQL_HOSTNAME" \
        --port="MYSQL_PORT" \
        --user="MYSQL_USER_NAME" \
        --password="MYSQL_USER_PASSWORD" \
        --no-data \
        --routines \
        --events \
        --triggers \
        --default-character-set=utf8mb4 \
        --databases "$DB_NAME" \
        --tables $STRUCTURE_ONLY_TABLES_EXPANDED > "$TMP_SCHEMA"
      echo "✅ Dumped schema for structure tables to: $TMP_SCHEMA"

      # Prepare ignore tables command for full dump
      IGNORE_TABLES_FULL_DUMP_CMD=$(echo "$STRUCTURE_ONLY_TABLES_EXPANDED" | sed "s/ / --ignore-table=${DB_NAME}./g" | sed "s/^/--ignore-table=${DB_NAME}./")
      echo "Prepared ignore tables command for full dump: [$IGNORE_TABLES_FULL_DUMP_CMD]"
    else
      echo "No matching structure-only tables found for $DB_NAME"
    fi
  fi

  # 2. Dump full DB (or DB minus structure tables)
  echo "Dumping full database $DB_NAME..."
  if ! $MYSQLDUMP \
    --skip-ssl \
    --host="MYSQL_HOSTNAME" \
    --port="MYSQL_PORT" \
    --user="MYSQL_USER_NAME" \
    --password="MYSQL_USER_PASSWORD" \
    --single-transaction \
    --quick \
    --skip-lock-tables \
    --routines \
    --events \
    --triggers \
    --hex-blob \
    --default-character-set=utf8mb4 \
    --set-gtid-purged=OFF \
    $IGNORE_TABLES_FULL_DUMP_CMD \
    "$DB_NAME" > "$TMP_DATA" 2>&1; then
    echo "❌ ERROR: Failed to dump database: $DB_NAME"
    echo "Check the error messages above for details."
    rm -f "$TMP_SCHEMA" "$TMP_DATA" "$TMP_COMBINED"
    return 1
  fi
  echo "✅ Dumped full database to: $TMP_DATA"

  # 3. Combine schema and data dumps if structure-only tables were found
  if [ -f "$TMP_SCHEMA" ]; then
    echo "Combining schema and data dumps for $DB_NAME..."
    cat "$TMP_SCHEMA" "$TMP_DATA" > "$TMP_COMBINED"
  else
    mv "$TMP_DATA" "$TMP_COMBINED"
  fi

  # 4. Strip lines containing "enable the sandbox mode" for compatibility with old versions
  # See: https://github.com/drush-ops/drush/issues/6027
  sed -i '/enable the sandbox mode/d' "$TMP_COMBINED"

  # 5. Compress the export
  echo "Compressing the export for $DB_NAME..."
  gzip -GZIP_COMPRESSION_LEVEL "$TMP_COMBINED"

  # 6. Move to final location
  mv "${TMP_COMBINED}.gz" "./${DB_NAME}.gz"

  # 7. Clean up temporary files
  rm -f "$TMP_SCHEMA" "$TMP_DATA" "$TMP_COMBINED"

  echo "✅ Backup completed for $DB_NAME: ./${DB_NAME}.gz"
  return 0
}

# Get list of databases to backup
get_database_list() {
  # Priority 1: Legacy single database mode (MYSQL_DATABASE)
  if [ -n "MYSQL_DATABASE" ]; then
    echo "MYSQL_DATABASE"
    return 0
  fi

  # Priority 2: Explicit list (MYSQL_DATABASES)
  if [ -n "MYSQL_DATABASES" ]; then
    echo "MYSQL_DATABASES" | tr ',' ' '
    return 0
  fi

  # Priority 3: Auto-discovery (MYSQL_BACKUP_ALL_DATABASES)
  if [ "MYSQL_BACKUP_ALL_DATABASES" = "true" ] || [ "MYSQL_BACKUP_ALL_DATABASES" = "1" ]; then
    echo "Auto-discovering databases..." >&2
    EXCLUDE_LIST="MYSQL_EXCLUDE_DATABASES"
    EXCLUDE_PATTERN=$(echo "$EXCLUDE_LIST" | tr ',' '|')

    DBS=$(mysql \
      --skip-ssl \
      --host="MYSQL_HOSTNAME" \
      --port="MYSQL_PORT" \
      --user="MYSQL_USER_NAME" \
      --password="MYSQL_USER_PASSWORD" \
      --batch --skip-column-names \
      -e "SHOW DATABASES;" 2>/dev/null | grep -vE "^(${EXCLUDE_PATTERN})$" || true)

    if [ -z "$DBS" ]; then
      echo "❌ ERROR: No databases found or unable to connect to MySQL server" >&2
      exit 1
    fi

    echo "$DBS"
    return 0
  fi

  # No configuration provided
  echo "❌ ERROR: No database configuration provided"
  echo "Please set one of: MYSQL_DATABASE, MYSQL_DATABASES, or MYSQL_BACKUP_ALL_DATABASES=true"
  exit 1
}

# Main execution
echo "=================================================="
echo "MySQL Backup Script"
echo "=================================================="

# Get list of databases to backup
DATABASE_LIST=$(get_database_list)
DATABASE_COUNT=$(echo "$DATABASE_LIST" | wc -w)

echo "Databases to backup: $DATABASE_COUNT"
echo "$DATABASE_LIST" | tr ' ' '\n' | sed 's/^/  - /'
echo ""

# Backup each database
for DB in $DATABASE_LIST; do
  if ! backup_single_database "$DB"; then
    echo "❌ Failed to backup database: $DB"
    BACKUP_FAILED=1
  fi
  echo ""
done

# Final summary
echo "=================================================="
if [ $BACKUP_FAILED -eq 0 ]; then
  echo "✅ All database backups completed successfully!"
  echo "=================================================="
  exit 0
else
  echo "⚠️  Some database backups failed. Please check the log above."
  echo "=================================================="
  exit 1
fi
