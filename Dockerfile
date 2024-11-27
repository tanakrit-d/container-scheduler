FROM alpine:latest AS base

ARG SUPERCRONIC_VERSION=v0.2.33
ARG TARGETARCH

ARG SUPERCRONIC_ARCH_AMD64="linux-amd64"
ARG SUPERCRONIC_SHA1_AMD64="71b0d58cc53f6bd72cf2f293e09e294b79c666d8"
ARG SUPERCRONIC_ARCH_ARM64="linux-arm64"
ARG SUPERCRONIC_SHA1_ARM64="e0f0c06ebc5627e43b25475711e694450489ab00"

RUN apk add --no-cache curl && \
    if [ "$TARGETARCH" = "arm64" ]; then \
        SUPERCRONIC_ARCH="$SUPERCRONIC_ARCH_ARM64" && \
        SUPERCRONIC_SHA1SUM="$SUPERCRONIC_SHA1_ARM64"; \
    elif [ "$TARGETARCH" = "amd64" ]; then \
        SUPERCRONIC_ARCH="$SUPERCRONIC_ARCH_AMD64" && \
        SUPERCRONIC_SHA1SUM="$SUPERCRONIC_SHA1_AMD64"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi && \
    SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/supercronic-${SUPERCRONIC_ARCH}" && \
    curl -fsSLO "$SUPERCRONIC_URL" && \
    echo "${SUPERCRONIC_SHA1SUM}  supercronic-${SUPERCRONIC_ARCH}" | sha1sum -c - && \
    mv "supercronic-${SUPERCRONIC_ARCH}" "/usr/local/bin/supercronic" && \
    chmod +x "/usr/local/bin/supercronic"

FROM alpine:latest

ARG TARGETARCH

ENV SUPERCRONIC=/usr/local/bin/supercronic

RUN apk add --no-cache \
        bash \
        curl \
        jq \
        procps \
        tzdata && \
    mkdir -p /app /var/log && \
    touch /var/log/cron.log

COPY --from=base /usr/local/bin/supercronic /usr/local/bin/supercronic
COPY container-schedules.cron functions.sh entrypoint.sh /app/

RUN addgroup -S docker && adduser -S scheduler -G docker && \
    chmod +x /app/entrypoint.sh /app/functions.sh /usr/local/bin/supercronic && \
    chown -R scheduler:docker /app /var/log

LABEL org.opencontainers.image.title="Scheduler Container" \
org.opencontainers.image.description="Scheduling container using supercronic" \
org.opencontainers.image.source="https://github.com/tanakrit-d/container-scheduler" \
io.container.scheduler.arch="${TARGETARCH}"

WORKDIR /app
VOLUME ["/var/log"]

USER scheduler

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
CMD ["sh", "-c", "ps aux | grep supercronic | grep -v grep > /dev/null || exit 1"]

ENTRYPOINT ["/app/entrypoint.sh"]