#!/usr/bin/env bash

set -euo pipefail

STATE_FILE="/tmp/dimarch-hypr-clients-before-sleep.json"
LOG="/tmp/dimarch-save-before-sleep.log"

{
    echo "[$(date '+%F %T')] saving clients before sleep"
    hyprctl clients -j > "$STATE_FILE"
    echo "[$(date '+%F %T')] saved to $STATE_FILE"
} > "$LOG" 2>&1
