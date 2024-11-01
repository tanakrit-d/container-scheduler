#!/bin/bash

restart_containers() {
    local group=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local containers=$(docker ps --filter "label=restart-group=${group}" --format '{{.Names}}')
    
    if [ -n "$containers" ]; then
        echo "[${timestamp}] Restarting ${group} containers: ${containers}"
        docker ps -q --filter "label=restart-group=${group}" | xargs -r docker restart
    else
        echo "[${timestamp}] No containers found for restart group: ${group}"
    fi
}