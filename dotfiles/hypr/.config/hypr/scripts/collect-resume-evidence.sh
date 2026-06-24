#!/usr/bin/env bash

# Collect evidence for BUG-01: which GPU apps disappear silently after resume.
# Called from restore-after-resume.sh. Reads STATE_FILE (pre-sleep clients)
# and compares against current clients to identify what closed during resume.

set -euo pipefail

STATE_FILE="/tmp/dimarch-hypr-clients-before-sleep.json"
EVIDENCE_DIR="/tmp/dimarch-resume-evidence"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
REPORT="$EVIDENCE_DIR/$TIMESTAMP.txt"

mkdir -p "$EVIDENCE_DIR"

{
    echo "=== DimArch Resume Evidence: $TIMESTAMP ==="
    echo ""

    echo "--- CLIENTS BEFORE SLEEP ---"
    if [ -s "$STATE_FILE" ]; then
        jq -r '.[] | [.class, .title, "floating=\(.floating)", "ws=\(.workspace.id)", .address] | @tsv' \
            "$STATE_FILE" 2>/dev/null
    else
        echo "(state file missing or empty)"
    fi

    echo ""
    echo "--- CLIENTS AFTER RESUME ---"
    hyprctl clients -j \
        | jq -r '.[] | [.class, .title, "floating=\(.floating)", "ws=\(.workspace.id)", .address] | @tsv' \
        2>/dev/null

    echo ""
    echo "--- DISAPPEARED CLIENTS (before but not after, matched by class+title) ---"
    if [ -s "$STATE_FILE" ]; then
        before_keys=$(jq -r '.[] | "\(.class)\t\(.title)"' "$STATE_FILE" 2>/dev/null | sort)
        after_keys=$(hyprctl clients -j | jq -r '.[] | "\(.class)\t\(.title)"' | sort)
        disappeared=$(comm -23 <(echo "$before_keys") <(echo "$after_keys"))
        if [ -n "$disappeared" ]; then
            echo "$disappeared"
        else
            echo "(none — all clients survived resume)"
        fi
    fi

    echo ""
    echo "--- JOURNAL: 5 min window around resume (amdgpu, drm, wayland, gpu, killed) ---"
    journalctl -b 0 --since "5 minutes ago" --no-pager \
        -g 'amdgpu|drm|wlopm|hyprland|chrome|chromium|firefox|electron|thunar|gpu|killed|oom|wayland' \
        2>/dev/null || echo "(journalctl failed)"

    echo ""
    echo "--- HYPRLAND LOG (last 200 lines) ---"
    tail -200 ~/.local/share/hyprland/hyprland.log 2>/dev/null || echo "(log not found)"

    echo ""
    echo "--- AMDGPU POWER STATE ---"
    for f in /sys/class/drm/card*/device/power_dpm_state; do
        [ -r "$f" ] && echo "$f: $(cat "$f")"
    done 2>/dev/null || echo "(not available)"

    echo ""
    echo "--- COREDUMPS (last hour) ---"
    coredumpctl list --since "1 hour ago" 2>/dev/null || echo "(none)"

} > "$REPORT" 2>&1

echo "[evidence] report saved: $REPORT"
