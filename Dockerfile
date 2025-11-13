FROM alpine:3.22

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ENV GZIP_COMPRESSION_LEVEL=6
ENV MYSQL_DUMP_LOCATION=/data
ENV MYSQL_HOSTNAME=localhost
ENV MYSQL_PORT=3306
ENV MYSQL_STRUCT_TABLES=""
ENV MYSQL_USER_NAME=root
ENV MYSQL_USER_PASSWORD=changeme
ENV MYSQL_DATABASES=""
ENV MYSQL_BACKUP_ALL_DATABASES=""
ENV MYSQL_EXCLUDE_DATABASES="information_schema,performance_schema,mysql,sys"
ENV RSNAPSHOT_RETAIN_DAILY=7
ENV RSNAPSHOT_RETAIN_HOURLY=8
ENV RSNAPSHOT_RETAIN_MONTHLY=6
ENV RSNAPSHOT_RETAIN_WEEKLY=4

RUN apk --update --no-cache add rsnapshot mysql-client && \
  touch /var/log/rsnapshot.log && \
  mkdir -p ${MYSQL_DUMP_LOCATION}

COPY ./build/conf/rsnapshot/rsnapshot.conf /etc/rsnapshot.conf
COPY ./build/scripts /scripts

ENTRYPOINT ["/scripts/run.sh"]

LABEL ca.unb.lib.generator="rsnapshot" \
  com.microscaling.docker.dockerfile="/Dockerfile" \
  com.microscaling.license="MIT" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.description="mysql-backup provides a MySQL backup for DB driven instances at UNB Libraries." \
  org.label-schema.name="mysql-backup" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/unb-libraries/docker-mysql-backup" \
  org.label-schema.vendor="University of New Brunswick Libraries" \
  org.label-schema.version=$VERSION \
  org.opencontainers.image.authors="UNB Libraries <libsupport@unb.ca>" \
  org.opencontainers.image.source="https://github.com/unb-libraries/docker-mysql-backup"
