# syntax=docker/dockerfile:1.4

FROM alpine:latest AS verify
ARG SUPERCRONIC_VERSION=v0.2.33
ARG TARGETARCH

RUN case "${TARGETARCH}" in \
    "arm64") SUPERCRONIC_ARCH="linux-arm64"; SUPERCRONIC_SHA1SUM="e0f0c06ebc5627e43b25475711e694450489ab00" ;; \
    "amd64") SUPERCRONIC_ARCH="linux-amd64"; SUPERCRONIC_SHA1SUM="71b0d58cc53f6bd72cf2f293e09e294b79c666d8" ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-${SUPERCRONIC_ARCH}" && \
    wget -O /tmp/supercronic ${SUPERCRONIC_URL} && \
    echo "${SUPERCRONIC_SHA1SUM}  /tmp/supercronic" | sha1sum -c -

FROM alpine:latest
ARG TARGETARCH
ARG SUPERCRONIC_VERSION=v0.2.33
ENV SUPERCRONIC=/usr/local/bin/supercronic
ENV SUPERCRONIC_OPTIONS="-json -quiet"

LABEL org.opencontainers.image.title="Scheduler Container" \
    org.opencontainers.image.version=${SUPERCRONIC_VERSION} \
    org.opencontainers.image.description="Scheduling container using supercronic" \
    org.opencontainers.image.source="https://github.com/aptible/supercronic"

RUN addgroup -g 1000 scheduler && \
    adduser -u 1000 -G scheduler -h /home/scheduler -D scheduler

RUN apk add --no-cache \
    bash \
    curl \
    tzdata \
    docker-cli \
    ca-certificates \
    su-exec \
    procps \
    jq

RUN mkdir -p /app /runtime /var/log && \
    chown -R scheduler:scheduler /runtime /var/log && \
    touch /var/log/cron.log && \
    chown scheduler:scheduler /var/log/cron.log

COPY --from=verify /tmp/supercronic ${SUPERCRONIC}
RUN chmod +x ${SUPERCRONIC}

COPY --chown=scheduler:scheduler functions.sh container-schedules.cron /app/
RUN chmod +x /app/functions.sh && \
    cp /app/functions.sh /runtime/ && \
    chown -R scheduler:scheduler /app

RUN cat <<'EOF' > /entrypoint.sh
#!/bin/sh
set -euo pipefail

if [ -e /var/run/docker.sock ]; then
    DOCKER_GID=$(stat -c "%g" /var/run/docker.sock)
    addgroup -g "${DOCKER_GID}" docker || true
    addgroup scheduler docker
fi

if ! [ -x "$SUPERCRONIC" ]; then
    echo "Error: $SUPERCRONIC is not executable"
    exit 1
fi

exec su-exec scheduler "$SUPERCRONIC" $SUPERCRONIC_OPTIONS /app/container-schedules.cron
EOF

RUN chmod +x /entrypoint.sh

WORKDIR /app
VOLUME ["/var/log"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ps aux | grep supercronic | grep -v grep > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]