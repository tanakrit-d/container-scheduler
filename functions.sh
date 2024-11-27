#!/bin/sh

restart_containers() {
    local group="$1"
    local timestamp

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    filters=$(echo "{\"label\":[\"restart-group=${group}\"]}" | jq -sRr @uri)

    containers=$(curl --silent --unix-socket /var/run/docker.sock \
        -X GET "http://localhost/containers/json?filters=${filters}" | \
        jq -r '.[].Id')

    if [ -n "$containers" ]; then
        echo "[${timestamp}] Restarting ${group} containers: ${containers}"

        for container_id in $containers; do
            if curl --silent --unix-socket /var/run/docker.sock \
                -X POST "http://localhost/containers/${container_id}/restart" > /dev/null; then
                echo "[${timestamp}] Successfully restarted container: ${container_id}"
            else
                echo "[${timestamp}] Failed to restart container: ${container_id}" >&2
            fi
        done
    else
        echo "[${timestamp}] No containers found for restart group: ${group}"
    fi
}