# Base stage
FROM alpine:latest AS base

ARG SUPERCRONIC_VERSION=v0.2.33
ARG TARGETARCH

ARG SUPERCRONIC_ARCH_AMD64="linux-amd64"
ARG SUPERCRONIC_SHA1_AMD64="71b0d58cc53f6bd72cf2f293e09e294b79c666d8"
ARG SUPERCRONIC_ARCH_ARM64="linux-arm64"
ARG SUPERCRONIC_SHA1_ARM64="e0f0c06ebc5627e43b25475711e694450489ab00"

RUN apk add --no-cache curl && \
    if [ "$TARGETARCH" = "arm64" ]; then \
        export SUPERCRONIC_ARCH="$SUPERCRONIC_ARCH_ARM64" && \
        export SUPERCRONIC_SHA1SUM="$SUPERCRONIC_SHA1_ARM64"; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
        export SUPERCRONIC_ARCH="$SUPERCRONIC_ARCH_AMD64" && \
        export SUPERCRONIC_SHA1SUM="$SUPERCRONIC_SHA1_AMD64"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi && \
    SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-${SUPERCRONIC_ARCH}" && \
    curl -fsSLO "$SUPERCRONIC_URL" && \
    echo "${SUPERCRONIC_SHA1SUM}  supercronic-${SUPERCRONIC_ARCH}" | sha1sum -c - && \
    chmod +x "supercronic-${SUPERCRONIC_ARCH}" && \
    mv "supercronic-${SUPERCRONIC_ARCH}" "/usr/local/bin/supercronic"

FROM alpine:latest

ARG TARGETARCH

ENV SUPERCRONIC=/usr/local/bin/supercronic \
    TZ=UTC

RUN addgroup -g 1000 scheduler && \
    adduser -u 1000 -G scheduler -h /home/scheduler -D scheduler && \
    apk add --no-cache \
        bash \
        curl \
        jq \
        procps \
        su-exec \
        tzdata && \
    mkdir -p /app /runtime /var/log && \
    chown -R scheduler:scheduler /runtime /var/log && \
    touch /var/log/cron.log && \
    chown scheduler:scheduler /var/log/cron.log && \
    rm -rf /var/cache/apk/*

COPY --from=base /usr/local/bin/supercronic /usr/local/bin/supercronic

RUN chmod +x /usr/local/bin/supercronic

COPY --chown=scheduler:scheduler functions.sh container-schedules.cron /app/
RUN chmod +x /app/functions.sh && \
    mv /app/functions.sh /runtime/ && \
    chown -R scheduler:scheduler /app

RUN cat <<'EOF' > /entrypoint.sh
#!/bin/sh
set -euo pipefail

if [ -e /var/run/docker.sock ]; then
    addgroup scheduler docker
fi

if ! [ -x "$SUPERCRONIC" ]; then
    echo "Error: $SUPERCRONIC is not executable"
    exit 1
fi

exec su-exec scheduler "$SUPERCRONIC" "-json" "-quiet" /app/container-schedules.cron
EOF

RUN chmod +x /entrypoint.sh

LABEL org.opencontainers.image.title="Scheduler Container" \
    org.opencontainers.image.description="Scheduling container using supercronic" \
    org.opencontainers.image.source="https://github.com/tanakrit-d/container-scheduler" \
    io.container.scheduler.arch="${TARGETARCH}"

WORKDIR /app
VOLUME ["/var/log"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep supercronic > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
