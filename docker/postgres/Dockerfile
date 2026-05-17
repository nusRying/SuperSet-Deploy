ARG POSTGRES_VERSION=16-alpine

FROM postgres:${POSTGRES_VERSION}

COPY docker/postgres/sync-password-entrypoint.sh /usr/local/bin/sync-password-entrypoint.sh

RUN chmod +x /usr/local/bin/sync-password-entrypoint.sh

ENTRYPOINT ["sync-password-entrypoint.sh"]
CMD ["postgres"]
