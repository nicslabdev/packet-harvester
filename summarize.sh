#!/bin/bash

# === HELP ===
show_help() {
    echo "📦 summarize_captures.sh - Capture Summary Tool"
    echo
    echo "This script analyzes all .pcapng files in the ./data directory and provides:"
    echo "  • Total number of capture files"
    echo "  • Number of captures per traffic type (grouped by filename prefix)"
    echo "  • Total packets and average packets per group"
    echo "  • Percentage of total packets per group"
    echo
    echo "📂 Input directory: ./data"
    echo
    echo "🧰 Dependencies:"
    echo "  - capinfos (from Wireshark)"
    echo
    echo "🛠 Options:"
    echo "  --help, -h             Show this help message"
    echo "  --fix-permissions      Change ownership of .pcapng files owned by 'tcpdump' to your user"
    echo
    echo "🧪 Example usage:"
    echo "  ./summarize_captures.sh"
    echo "  ./summarize_captures.sh --fix-permissions"
    echo
    exit 0
}

# === HANDLE --help ===
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
fi

# === CHECK capinfos ===
if ! command -v capinfos &> /dev/null; then
    echo "❌ Error: 'capinfos' is not installed or not in PATH."
    echo "👉 You can install it with: sudo apt install wireshark-common"
    exit 1
fi

# === SET DIRECTORY ===
DATA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/data" && pwd)"
cd "$DATA_DIR" || { echo "❌ Could not access data directory."; exit 1; }

# === HANDLE --fix-permissions ===
if [[ "$1" == "--fix-permissions" ]]; then
    echo "🔧 Fixing ownership of .pcapng files owned by 'tcpdump'..."
    count=0
    for f in *.pcapng; do
        [[ -f "$f" ]] || continue
        owner=$(stat -c %U "$f")
        if [[ "$owner" == "tcpdump" ]]; then
            echo "⚙️  Changing owner of: $f"
            sudo chown "$USER:$USER" "$f"
            ((count++))
        fi
    done

    if [[ "$count" -eq 0 ]]; then
        echo "✅ No files needed fixing."
    else
        echo "✅ Fixed ownership of $count file(s)."
    fi
    exit 0
fi

# === START ANALYSIS ===
echo "📊 Analyzing capture files in: $DATA_DIR"
echo

TOTAL_FILES=$(ls *.pcapng 2>/dev/null | wc -l)
if [[ "$TOTAL_FILES" -eq 0 ]]; then
    echo "No .pcapng files found."
    exit 0
fi

echo "📁 Total capture files: $TOTAL_FILES"
echo

declare -A GROUP_COUNTS
declare -A GROUP_PACKET_TOTALS

TOTAL_PACKETS=0
UNREADABLE_COUNT=0
FIXABLE_FILES=0

for file in *.pcapng; do
    [[ -f "$file" ]] || continue

    # Extract clean packet count (no commas)
    packet_count=$(capinfos -c "$file" 2>/dev/null | awk -F ':' '/Number of packets/ {gsub(",", "", $2); print $2}' | xargs)

    if [[ -z "$packet_count" || ! "$packet_count" =~ ^[0-9]+$ ]]; then
        echo "⚠️  Skipping unreadable file: $file"
        owner=$(stat -c %U "$file")
        if [[ "$owner" == "tcpdump" ]]; then
            echo "   💡 Tip: The file is owned by 'tcpdump'."
            echo "      👉 Run: ./summarize_captures.sh --fix-permissions"
            ((FIXABLE_FILES++))
        fi
        ((UNREADABLE_COUNT++))
        continue
    fi

    group=$(echo "$file" | cut -d'_' -f1)
    GROUP_COUNTS["$group"]=$((GROUP_COUNTS["$group"] + 1))
    GROUP_PACKET_TOTALS["$group"]=$((GROUP_PACKET_TOTALS["$group"] + packet_count))
    TOTAL_PACKETS=$((TOTAL_PACKETS + packet_count))
done

# === PRINT TABLE ===
printf "%-20s %10s %15s %15s %10s\n" "Traffic Type" "Captures" "Total Packets" "Avg. Packets" "% of Total"
printf "%-20s %10s %15s %15s %10s\n" "------------" "--------" "--------------" "--------------" "----------"

for group in "${!GROUP_COUNTS[@]}"; do
    count=${GROUP_COUNTS[$group]}
    total=${GROUP_PACKET_TOTALS[$group]}
    avg=$((total / count))
    percent=$(awk "BEGIN { printf \"%.2f\", ($total * 100) / $TOTAL_PACKETS }")

    printf "%-20s %10d %15d %15d %9s%%\n" "$group" "$count" "$total" "$avg" "$percent"
done

echo
echo "📦 Total packets across all captures: $TOTAL_PACKETS"

if [[ "$UNREADABLE_COUNT" -gt 0 ]]; then
    echo "⚠️  $UNREADABLE_COUNT file(s) could not be read."
    if [[ "$FIXABLE_FILES" -gt 0 ]]; then
        echo "💡 Some are owned by 'tcpdump'. You can fix this with:"
        echo "   ./summarize_captures.sh --fix-permissions"
    fi
fi
