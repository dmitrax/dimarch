#!/usr/bin/env bash
# Keyboard layout switching — macOS-style MRU tap + direct-pick menu.
# Layout order must match kb_layout in modules/input.lua (us,ru,ua).

STATE_FILE="/tmp/dimarch-kb-layout-mru"
NAMES=("English (US)" "Русский" "Українська")

current_index() {
    hyprctl devices -j | python3 -c "
import sys, json
d = json.load(sys.stdin)
print([k['active_layout_index'] for k in d['keyboards'] if k['main']][0])
"
}

mru() {
    local current previous target
    current=$(current_index)
    previous=$(cat "$STATE_FILE" 2>/dev/null || echo "$current")

    if [ "$previous" = "$current" ]; then
        target=$(( (current + 1) % ${#NAMES[@]} ))
    else
        target="$previous"
    fi

    echo "$current" > "$STATE_FILE"
    hyprctl switchxkblayout all "$target"
}

menu() {
    local current chosen i

    # Enter the dedicated submap so the global Alt+Space bind steps aside —
    # the keypress then reaches rofi, which treats it as "next row" below.
    # Reset is trapped so a killed/crashed rofi can't leave Hyprland stuck
    # in this submap (that would silently break the Alt+Space MRU tap).
    hyprctl eval "hl.dispatch(hl.dsp.submap('kblayoutpicker'))" >/dev/null
    trap "hyprctl eval \"hl.dispatch(hl.dsp.submap('reset'))\" >/dev/null" EXIT

    current=$(current_index)
    chosen=$(printf '%s\n' "${NAMES[@]}" | rofi -dmenu -p "Раскладка" -selected-row "$current" \
        -kb-row-down "Down,Control+n,Alt+space")

    hyprctl eval "hl.dispatch(hl.dsp.submap('reset'))" >/dev/null
    trap - EXIT

    for i in "${!NAMES[@]}"; do
        if [ "${NAMES[$i]}" = "$chosen" ]; then
            echo "$current" > "$STATE_FILE"
            hyprctl switchxkblayout all "$i"
            break
        fi
    done
}

case "$1" in
    mru)  mru ;;
    menu) menu ;;
    *) echo "usage: kb-layout.sh {mru|menu}" >&2; exit 1 ;;
esac
