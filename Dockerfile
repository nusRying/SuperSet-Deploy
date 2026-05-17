FROM apache/superset:latest

USER root

ARG SUPERSET_PIP_PACKAGES="psycopg2-binary redis gevent openpyxl"

RUN . /app/.venv/bin/activate && \
    uv pip install ${SUPERSET_PIP_PACKAGES}

COPY --chown=superset:superset docker/superset_config.py /app/pythonpath/superset_config.py
COPY --chown=superset:superset docker/*.sh /app/docker/

RUN chmod +x /app/docker/*.sh

ENV SUPERSET_CONFIG_PATH=/app/pythonpath/superset_config.py \
    PYTHONPATH=/app/pythonpath

EXPOSE 8088

USER superset
