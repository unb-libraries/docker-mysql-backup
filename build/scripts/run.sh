#!/usr/bin/env sh
for i in /scripts/pre-init.d/*sh
do
  if [ -e "${i}" ]; then
    echo "[i] pre-init.d - processing $i"
    . "${i}"
  fi
done

FREQUENCY=${1:-hourly}

echo "Configuration:"
cat /etc/rsnapshot.conf
echo "Running Backup..."

/usr/bin/rsnapshot -c /etc/rsnapshot.conf $FREQUENCY
