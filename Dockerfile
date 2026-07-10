FROM alpine:3.13

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL ca.unb.lib.generator="rsnapshot" \
  org.opencontainers.image.title="mysql-backup" \
  org.opencontainers.image.description="mysql-backup provides a MySQL backup for DB driven instances at UNB Libraries." \
  org.opencontainers.image.vendor="University of New Brunswick Libraries" \
  org.opencontainers.image.authors="Jacob Sanford <jsanford_at_unb.ca>" \
  org.opencontainers.image.source="https://github.com/unb-libraries/docker-mysql-backup" \
  org.opencontainers.image.version="$VERSION" \
  org.opencontainers.image.revision="$VCS_REF" \
  org.opencontainers.image.created="$BUILD_DATE"

ENV MYSQL_HOSTNAME="localhost"
ENV MYSQL_PORT="3306"
ENV MYSQL_USER_NAME="root"
ENV MYSQL_USER_PASSWORD="changeme"
ENV MYSQL_DUMP_LOCATION="/data"

ENV RSNAPSHOT_RETAIN_HOURLY="8"
ENV RSNAPSHOT_RETAIN_DAILY="7"
ENV RSNAPSHOT_RETAIN_WEEKLY="4"
ENV RSNAPSHOT_RETAIN_MONTHLY="6"

RUN apk --update add rsnapshot mysql-client && \
  touch /var/log/rsnapshot.log && \
  rm -f /var/cache/apk/* && \
  mkdir -p ${MYSQL_DUMP_LOCATION}

COPY ./conf/rsnapshot/rsnapshot.conf /etc/rsnapshot.conf
COPY scripts /scripts

ENTRYPOINT ["/scripts/run.sh"]
