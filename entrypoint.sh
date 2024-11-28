#!/bin/sh

if [ -n "$HOST_DOCKER_GID" ]; then
    groupmod -g "$HOST_DOCKER_GID" docker
    adduser scheduler docker
    chown -R scheduler:docker /app /var/log /var/log/cron.log
    printf "Info: Permissions set; GID for docker set to: $HOST_DOCKER_GID; scheduler added to group.\n"
    printf "-----\n"
fi

if [ -e /var/run/docker.sock ]; then
    printf "Info: Docker socket exists. Ensure your container has the correct permissions to access it.\n"
    printf "If the host is MacOS, you will need to implement forwarding.\n"
    printf "See: https://forums.docker.com/t/mounting-using-var-run-docker-sock-in-a-container-not-running-as-root/34390/8\n"
    printf "-----\n"
fi

if [ ! -x /usr/local/bin/supercronic ]; then
    printf "Error: /usr/local/bin/supercronic does not exist or is not executable.\n" >&2
    exit 1
fi

CRON_FILE="${1:-/app/container-schedules.cron}"

if [ ! -f "$CRON_FILE" ]; then
    printf "Error: Cron file '%s' does not exist.\n" "$CRON_FILE" >&2
    exit 1
fi

exec su-exec scheduler /usr/local/bin/supercronic -json -quiet "$CRON_FILE"