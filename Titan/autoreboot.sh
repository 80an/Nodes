#!/bin/bash

IMAGE_NAME="nezha123/titan-edge"
CHECK_INTERVAL=60
LOG_FILE="/var/log/titan-monitor.log"

while true; do
    CONTAINER_ID=$(docker ps -q --filter "ancestor=$IMAGE_NAME")

    if [ -z "$CONTAINER_ID" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Контейнер не работает, перезапускаю..." | tee -a "$LOG_FILE"
        docker restart $(docker ps -aq --filter "ancestor=$IMAGE_NAME") &>/dev/null
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Контейнер работает (ID: $CONTAINER_ID)" | tee -a "$LOG_FILE"
    fi

    sleep $CHECK_INTERVAL
done
