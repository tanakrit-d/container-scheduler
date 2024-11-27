#!/bin/bash

set -euo pipefail

if [ -e /var/run/docker.sock ]; then
    if ! getent group docker >/dev/null; then
        echo "Error: docker group does not exist. Please create it with 'groupadd docker' before running this script."
        exit 1
    fi
fi

if [ ! -x /usr/local/bin/supercronic ]; then
    echo "Error: /usr/local/bin/supercronic does not exist or is not executable."
    exit 1
fi

CRON_FILE="${1:-/app/container-schedules.cron}"

if [ ! -f "$CRON_FILE" ]; then
    echo "Error: Cron file $CRON_FILE does not exist."
    exit 1
fi

exec su-exec scheduler /usr/local/bin/supercronic -json -quiet "$CRON_FILE"