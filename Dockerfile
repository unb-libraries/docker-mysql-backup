FROM alpine:3.13
MAINTAINER Jacob Sanford <jsanford_at_unb.ca>

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
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
  org.opencontainers.image.source="https://github.com/unb-libraries/docker-mysql-backup"

ENV MYSQL_HOSTNAME localhost
ENV MYSQL_PORT 3306
ENV MYSQL_USER_NAME root
ENV MYSQL_USER_PASSWORD changeme
ENV MYSQL_DUMP_LOCATION /data

ENV RSNAPSHOT_RETAIN_HOURLY 8
ENV RSNAPSHOT_RETAIN_DAILY 7
ENV RSNAPSHOT_RETAIN_WEEKLY 4
ENV RSNAPSHOT_RETAIN_MONTHLY 6

RUN apk --update add rsnapshot mysql-client && \
  touch /var/log/rsnapshot.log && \
  rm -f /var/cache/apk/* && \
  mkdir -p ${MYSQL_DUMP_LOCATION}

COPY ./conf/rsnapshot/rsnapshot.conf /etc/rsnapshot.conf
COPY scripts /scripts

ENTRYPOINT ["/scripts/run.sh"]
