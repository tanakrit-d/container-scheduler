#!/bin/bash

set -euo pipefail

if [ -e /var/run/docker.sock ]; then
    echo "Info: docker socket exists. Ensure your container has the correct permissions to access it."
    echo "If the host is MacOS you will need to implement forwarding."
    echo "See https://forums.docker.com/t/mounting-using-var-run-docker-sock-in-a-container-not-running-as-root/34390/8"
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

exec /usr/local/bin/supercronic -json -quiet "$CRON_FILE"