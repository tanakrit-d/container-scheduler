FROM alpine:latest AS base
ARG SUPERCRONIC_VERSION=v0.2.33
ARG TARGETARCH

ARG SUPERCRONIC_ARCH_AMD64="linux-amd64"
ARG SUPERCRONIC_SHA1_AMD64="71b0d58cc53f6bd72cf2f293e09e294b79c666d8"
ARG SUPERCRONIC_ARCH_ARM64="linux-arm64"
ARG SUPERCRONIC_SHA1_ARM64="e0f0c06ebc5627e43b25475711e694450489ab00"

RUN case "${TARGETARCH}" in \
    "arm64") SUPERCRONIC_ARCH="${SUPERCRONIC_ARCH_ARM64}"; SUPERCRONIC_SHA1SUM="${SUPERCRONIC_SHA1_ARM64}" ;; \
    "amd64") SUPERCRONIC_ARCH="${SUPERCRONIC_ARCH_AMD64}"; SUPERCRONIC_SHA1SUM="${SUPERCRONIC_SHA1_AMD64}" ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac

COPY wget -O /tmp/supercronic "https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-${SUPERCRONIC_ARCH}"

RUN echo "${SUPERCRONIC_SHA1SUM}  /tmp/supercronic" | sha1sum -c - && \
    chmod +x /tmp/supercronic

FROM alpine:latest
ARG TARGETARCH

ENV SUPERCRONIC=/usr/local/bin/supercronic \
    SUPERCRONIC_OPTIONS="-json -quiet" \
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

COPY --from=base /tmp/supercronic ${SUPERCRONIC}
RUN chmod +x ${SUPERCRONIC}

COPY --chown=scheduler:scheduler functions.sh container-schedules.cron /app/
RUN chmod +x /app/functions.sh && \
    mv /app/functions.sh /runtime/ && \
    chown -R scheduler:scheduler /app && \
    cat <<'EOF' > /entrypoint.sh
    #!/bin/sh
    set -euo pipefail

    if [ -e /var/run/docker.sock ]; then
    addgroup scheduler docker
    fi

    if ! [ -x "$SUPERCRONIC" ]; then
        echo "Error: $SUPERCRONIC is not executable"
        exit 1
    fi
    exec su-exec scheduler "$SUPERCRONIC" $SUPERCRONIC_OPTIONS /app/container-schedules.cron
    EOF

RUN chmod +x /entrypoint.sh

LABEL org.opencontainers.image.title="Scheduler Container" \
    org.opencontainers.image.description="Scheduling container using supercronic" \
    org.opencontainers.image.source="https://github.com/tanakrit-d/container-scheduler" \
    io.container.scheduler.arch="${TARGETARCH}"

WORKDIR /app
VOLUME ["/var/log"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ps aux | grep supercronic | grep -v grep > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
