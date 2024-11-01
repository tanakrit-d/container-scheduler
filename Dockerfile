FROM alpine:latest

ARG TARGETARCH
ARG SUPERCRONIC_VERSION=v0.2.33
ENV SUPERCRONIC=/usr/local/bin/supercronic

RUN apk add --no-cache bash curl tzdata docker-cli ca-certificates su-exec && \
    case "${TARGETARCH}" in \
        "arm64") SUPERCRONIC_ARCH="linux-arm64"; SUPERCRONIC_SHA1SUM="e0f0c06ebc5627e43b25475711e694450489ab00" ;; \
        "amd64") SUPERCRONIC_ARCH="linux-amd64"; SUPERCRONIC_SHA1SUM="71b0d58cc53f6bd72cf2f293e09e294b79c666d8" ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-${SUPERCRONIC_ARCH}" && \
    curl -fsSL -o /tmp/supercronic ${SUPERCRONIC_URL} && \
    echo "${SUPERCRONIC_SHA1SUM}  /tmp/supercronic" | sha1sum -c - && \
    chmod +x /tmp/supercronic && mv /tmp/supercronic ${SUPERCRONIC} && \
    mkdir -p /app /runtime /var/log && \
    addgroup -g 1000 scheduler && \
    adduser -u 1000 -G scheduler -h /home/scheduler -D scheduler && \
    chown -R scheduler:scheduler /runtime /var/log && \
    touch /var/log/cron.log && chown scheduler:scheduler /var/log/cron.log

COPY functions.sh container-schedules.cron /app/
RUN chmod +x /app/functions.sh && cp /app/functions.sh /runtime/ && \
    chown -R scheduler:scheduler /app

RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'set -euo pipefail' >> /entrypoint.sh && \
    echo 'DOCKER_GID=$(stat -c "%g" /var/run/docker.sock)' >> /entrypoint.sh && \
    echo 'addgroup -g "${DOCKER_GID}" docker' >> /entrypoint.sh && \
    echo 'adduser scheduler docker' >> /entrypoint.sh && \
    echo 'exec su-exec scheduler ${SUPERCRONIC} -debug /app/container-schedules.cron' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

WORKDIR /app
VOLUME ["/var/log", "/runtime"]

ENTRYPOINT ["/entrypoint.sh"]