#!/usr/bin/env sh
sed -i "s|MYSQL_DUMP_LOCATION|$MYSQL_DUMP_LOCATION|g" /etc/rsnapshot.conf

for TIMEFRAME in RSNAPSHOT_RETAIN_HOURLY RSNAPSHOT_RETAIN_DAILY RSNAPSHOT_RETAIN_WEEKLY RSNAPSHOT_RETAIN_MONTHLY
do
  eval TIMEFRAME_VALUE=\$$TIMEFRAME
  if [ "$TIMEFRAME_VALUE" == '0' ]; then
    sed -i "/$TIMEFRAME/d" /etc/rsnapshot.conf
  else
    sed -i "s|$TIMEFRAME|$TIMEFRAME_VALUE|g" /etc/rsnapshot.conf
  fi
done
