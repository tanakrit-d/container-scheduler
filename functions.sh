#!/bin/sh

restart_containers() {
    local group=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local containers=$(curl --silent --unix-socket /var/run/docker.sock \
        -X GET "http://localhost/containers/json?filters={\"label\":[\"restart-group=${group}\"]}" | \
        jq -r '.[].Id')

    if [ -n "$containers" ]; then
        echo "[${timestamp}] Restarting ${group} containers: ${containers}"
        
        for container_id in $containers; do
            curl --silent --unix-socket /var/run/docker.sock \
                -X POST "http://localhost/containers/${container_id}/restart" > /dev/null
        done
    else
        echo "[${timestamp}] No containers found for restart group: ${group}"
    fi
}