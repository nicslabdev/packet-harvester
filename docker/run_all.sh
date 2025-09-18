#!/bin/bash

URL_FILE="/app/urls.txt"
REPEATS=${1:-1}  # How many captures per URL
DATA_DIR="/app/data"
SLEEP_TIME=${SLEEP_TIME:-5}       # Seconds to wait after page load
PAGE_TIMEOUT=${PAGE_TIMEOUT:-0}   # Max page load timeout (0 = disabled)

mkdir -p "$DATA_DIR"

while read -r LINE; do
    [[ -z "$LINE" ]] && continue  # Skip empty lines

    # Extract alias and URL
    ALIAS=$(echo "$LINE" | awk '{print $1}')
    URL=$(echo "$LINE" | awk '{print $2}')

    if [[ -z "$URL" ]]; then
        URL="$ALIAS"
        ALIAS=$(echo "$URL" | awk -F[/:] '{print $4}' | awk -F. '{if (NF>2) print $2; else print $1}')
    fi

    for ((j = 1; j <= REPEATS; j++)); do
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        FILENAME="${ALIAS}_${TIMESTAMP}"
        echo "🌐 Visiting $URL → $FILENAME.pcapng"

        if [[ "$PAGE_TIMEOUT" -gt 0 ]]; then
            SLEEP_ENV="SLEEP_TIME=$SLEEP_TIME" PAGE_ENV="PAGE_TIMEOUT=$PAGE_TIMEOUT" /app/capture_traffic.sh "$FILENAME" "$URL" --no-timestamp --verbose
        else
            SLEEP_ENV="SLEEP_TIME=$SLEEP_TIME" /app/capture_traffic.sh "$FILENAME" "$URL" --no-timestamp --verbose
        fi

        sleep 1
    done

done < "$URL_FILE"
