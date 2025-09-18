#!/bin/bash

IMAGE_NAME="packet-harvester"
REPEATS=1
URLS_FILE="./urls.txt"
DATA_DIR="./data"
SLEEP_TIME=5
PAGE_TIMEOUT=0

print_help() {
    echo "🚀 PacketHarvester - Run Captures"
    echo
    echo "Usage:"
    echo "  ./run.sh [repeats] [options]"
    echo
    echo "Positional:"
    echo "  repeats              Number of captures per URL (default: 1)"
    echo
    echo "Options:"
    echo "  --urls PATH          Path to urls.txt (default: ./urls.txt)"
    echo "  --output PATH        Output directory (default: ./data)"
    echo "  --sleep N            Seconds to wait after load (default: 5)"
    echo "  --timeout N          Page load timeout in seconds (0 = disabled)"
    echo "  --help, -h           Show this help message"
    echo
}

# Handle first positional arg if numeric
if [[ "$1" =~ ^[0-9]+$ ]]; then
    REPEATS="$1"
    shift
fi

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --urls)
            URLS_FILE="$2"
            shift 2
            ;;
        --output)
            DATA_DIR="$2"
            shift 2
            ;;
        --sleep)
            SLEEP_TIME="$2"
            shift 2
            ;;
        --timeout)
            PAGE_TIMEOUT="$2"
            shift 2
            ;;
        help|-h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

# Check environment
echo "🔍 Checking environment..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed."
    exit 1
fi

if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "❌ Docker image '$IMAGE_NAME' not found. Run ./setup.sh build first."
    exit 1
fi

if [[ ! -f "$URLS_FILE" ]]; then
    echo "❌ File not found: $URLS_FILE"
    exit 1
fi

mkdir -p "$DATA_DIR"

echo "🚀 Starting capture: $REPEATS repetition(s) per URL"
echo "⏱️  Sleep after load: $SLEEP_TIME s | Timeout: $PAGE_TIMEOUT s"

docker run --rm -it \
  --cap-add=NET_ADMIN \
  -v "$(realpath "$DATA_DIR"):/app/data" \
  -v "$(realpath "$URLS_FILE"):/app/urls.txt" \
  -e SLEEP_TIME="$SLEEP_TIME" \
  -e PAGE_TIMEOUT="$PAGE_TIMEOUT" \
  "$IMAGE_NAME" \
  ./run_all.sh "$REPEATS"

echo "✅ Done. Captures saved in: $DATA_DIR"
