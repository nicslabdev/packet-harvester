#!/bin/bash

SCRIPT_DIR="/app"
DATA_DIR="$SCRIPT_DIR/data"
mkdir -p "$DATA_DIR"

# Argument parsing
ADD_TIMESTAMP=true
VERBOSE=false
POSITIONAL_ARGS=()

for arg in "$@"; do
    case "$arg" in
        --no-timestamp|-f) ADD_TIMESTAMP=false ;;
        --verbose|-v) VERBOSE=true ;;
        --help|-h)
            echo "Usage: $0 base_name URL [options]"
            exit 0 ;;
        *) POSITIONAL_ARGS+=("$arg") ;;
    esac
done

if [[ ${#POSITIONAL_ARGS[@]} -lt 2 ]]; then
    echo "❌ Missing arguments"
    exit 1
fi

BASE_NAME="${POSITIONAL_ARGS[0]}"
TARGET_URL="${POSITIONAL_ARGS[1]}"

if [[ ! "$TARGET_URL" =~ ^https?:// ]]; then
    echo "❌ Invalid URL"
    exit 1
fi

if $ADD_TIMESTAMP; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    FINAL_NAME="${BASE_NAME}_${TIMESTAMP}"
else
    FINAL_NAME="${BASE_NAME}"
fi

PCAP_FILE="$DATA_DIR/${FINAL_NAME}.pcapng"

$VERBOSE && echo "📡 Capturing traffic to $PCAP_FILE"

sudo tcpdump -i eth0 -w "$PCAP_FILE" "port 80 or port 443" > /dev/null 2>&1 &
#sudo tcpdump -i eth0 -w "$PCAP_FILE" "tcp port 443 and tcp[13] & 0x1f == 0x10 and greater 0" > /dev/null 2>&1 &
TCPDUMP_PID=$!
sleep 2

$VERBOSE && echo "🚀 Running Selenium"
SLEEP_TIME=${SLEEP_TIME:-5}
PAGE_TIMEOUT=${PAGE_TIMEOUT:-0}

if [[ "$PAGE_TIMEOUT" -gt 0 ]]; then
  python3 "$SCRIPT_DIR/request.py" "$TARGET_URL" "$VERBOSE" "$SLEEP_TIME" "$PAGE_TIMEOUT"
else
  python3 "$SCRIPT_DIR/request.py" "$TARGET_URL" "$VERBOSE" "$SLEEP_TIME"
fi


$VERBOSE && echo "🛑 Stopping tcpdump"
kill -SIGTERM $TCPDUMP_PID
wait $TCPDUMP_PID 2>/dev/null

$VERBOSE && echo "✅ Done. File saved at $PCAP_FILE"
