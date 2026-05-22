#!/usr/bin/env bash

set -euo pipefail

STATE_FILE="/tmp/dimarch-hypr-clients-before-sleep.json"
LOG="/tmp/dimarch-restore-after-resume.log"

# Overwrite log on each resume cycle.
: > "$LOG"

log() {
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG"
}

run() {
    log "RUN: $*"
    "$@" >> "$LOG" 2>&1 || log "FAILED: $*"
}

wait_for_monitors() {
    log "waiting for DP-1 and DP-2"

    for i in {1..40}; do
        if hyprctl monitors | grep -q '^Monitor DP-1' && hyprctl monitors | grep -q '^Monitor DP-2'; then
            log "both monitors detected on attempt $i"
            return 0
        fi

        log "waiting for monitors... attempt $i"
        sleep 0.25
    done

    log "monitors were not both detected in time"
    return 1
}

apply_monitor_layout() {
    log "applying monitor layout"

    # DP-2 = Dell FullHD, left.
    # DP-1 = LG 4K, right, scale 1.5.
    run hyprctl eval 'hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "0x0", scale = 1 })'
    run hyprctl eval 'hl.monitor({ output = "DP-1", mode = "3840x2160@60", position = "1920x0", scale = 1.5 })'
}

restore_clients_from_state() {
    if [ ! -s "$STATE_FILE" ]; then
        log "state file missing or empty: $STATE_FILE"
        return 0
    fi

    log "restoring floating clients from saved state"

    jq -r '
        .[]
        | select(.floating == true)
        | select(.workspace.id >= 1 and .workspace.id <= 9)
        | [.address, .workspace.id, .at[0], .at[1], .size[0], .size[1], .class, .title]
        | @tsv
    ' "$STATE_FILE" | while IFS=$'\t' read -r addr ws x y w h class title; do
        # Restore only windows that still exist after resume.
        if ! hyprctl clients -j | jq -e --arg addr "$addr" '.[] | select(.address == $addr)' >/dev/null; then
            log "skip missing window addr=$addr class=$class title=$title"
            continue
        fi

        log "restore addr=$addr ws=$ws pos=${x},${y} size=${w}x${h} class=$class title=$title"

        # Restore saved workspace.
        run hyprctl dispatch "hl.dsp.window.move({ workspace = ${ws}, window = \"address:${addr}\" })"

        # Restore saved size.
        run hyprctl dispatch "hl.dsp.window.resize({ x = ${w}, y = ${h}, window = \"address:${addr}\" })"

        # Restore saved position.
        run hyprctl dispatch "hl.dsp.window.move({ x = ${x}, y = ${y}, window = \"address:${addr}\" })"
    done
}

ensure_waybar() {
    log "checking waybar"

    if ! pgrep -x waybar >/dev/null; then
        log "waybar is not running, starting"
        waybar >/tmp/waybar.log 2>&1 &
    else
        log "waybar is already running"
    fi
}

log "restore started"

# Give Hyprland/Wayland time to process monitor hotplug after resume.
sleep 2

wait_for_monitors || exit 0

# Let DP-1 stabilize after reappearing.
sleep 1

apply_monitor_layout

# Give Hyprland a moment to settle layout.
sleep 1

# Restore exact saved floating window geometry.
restore_clients_from_state

ensure_waybar

log "restore finished"

log "monitors after restore:"
hyprctl monitors >> "$LOG" 2>&1 || true

log "workspaces after restore:"
hyprctl workspaces >> "$LOG" 2>&1 || true

log "clients after restore:"
hyprctl clients -j | jq '.[] | {class, title, workspace: .workspace.id, floating, at, size, address}' >> "$LOG" 2>&1 || true
