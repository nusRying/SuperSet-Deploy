ARG POSTGRES_VERSION=16-alpine

FROM postgres:${POSTGRES_VERSION}

COPY docker/postgres/sync-password-entrypoint.sh /usr/local/bin/sync-password-entrypoint.sh
COPY docker/postgres/healthcheck.sh /usr/local/bin/postgres-healthcheck.sh

RUN chmod +x /usr/local/bin/sync-password-entrypoint.sh /usr/local/bin/postgres-healthcheck.sh

ENTRYPOINT ["sync-password-entrypoint.sh"]
CMD ["postgres"]
