#!/bin/sh

restart_containers() {
    local group="$1"
    local timestamp

    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    filters=$(echo "{\"label\":[\"restart-group=${group}\"]}" | jq -sRr @uri)

    containers=$(curl --silent --unix-socket /var/run/docker.sock \
        -X GET "http://localhost/containers/json?filters=${filters}" | \
        jq -r '.[].Names[]' | sed 's|/||') 

    if [ -n "$containers" ]; then
        echo "[${timestamp}] Stopping ${group} containers: ${containers}"

        for container_name in $containers; do
            if curl --silent --unix-socket /var/run/docker.sock \
                -X POST "http://localhost/containers/${container_name}/stop" > /dev/null; then
                echo "[${timestamp}] Successfully stopped containers: ${container_name}"

                # Wait a short time to ensure the container has stopped cleanly
                sleep 1

                if curl --silent --unix-socket /var/run/docker.sock \
                    -X POST "http://localhost/containers/${container_name}/start" > /dev/null; then
                    echo "[${timestamp}] Successfully started containers: ${container_name}"
                else
                    echo "[${timestamp}] Failed to start containers: ${container_name}" >&2
                fi
            else
                echo "[${timestamp}] Failed to stop containers: ${container_name}" >&2
            fi
        done
    else
        echo "[${timestamp}] No containers found for restart group: ${group}"
    fi
}