#!/usr/bin/env bash

set -euo pipefail

SCREENSHOT_DIR="${XDG_SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
FILE="$SCREENSHOT_DIR/Screenshot_${TIMESTAMP}.png"

MODE="${1:-area}"

# Satty toolbar height in pixels
SATTY_TOOLBAR=50

notify_saved() {
    command -v notify-send >/dev/null 2>&1 && \
        notify-send "Screenshot saved" "$FILE"
}

copy_file_to_clipboard() {
    wl-copy --type image/png < "$FILE"
}

select_region() {
    # Selection border is the sage brand accent (was #2f7d68 — an orphan dark
    # green that existed only here and in hyprlock's check_color; both pulled
    # onto the palette 2026-07-26). Backdrop stays neutral black so it dims
    # the screen without tinting it.
    slurp \
        -d \
        -b 00000055 \
        -c 7fb89eff \
        -w 2
}

# Parse "x,y WxH" → sets W and H variables
parse_geo() {
    local geo="$1"
    local dims="${geo##* }"
    W="${dims%x*}"
    H="${dims#*x}"
}

# Open pipe in satty and resize window to match screenshot dimensions
open_satty() {
    local w="$1"
    local h="$2"
    local win_h=$((h + SATTY_TOOLBAR))

    (
        for _ in $(seq 20); do
            sleep 0.1
            addr=$(hyprctl clients -j 2>/dev/null | \
                jq -r '[.[] | select(.class == "com.gabm.satty")] | last | .address // empty')
            [ -n "$addr" ] && {
                hyprctl dispatch resizewindowpixel \
                    "exact $w $win_h,address:$addr" 2>/dev/null
                break
            }
        done
    ) &

    cat | satty --filename -
}

case "$MODE" in
    area)
        GEO="$(select_region)"
        [ -z "$GEO" ] && exit 0
        sleep 0.20
        grim -g "$GEO" "$FILE"
        copy_file_to_clipboard
        notify_saved
        ;;

    area-edit)
        GEO="$(select_region)"
        [ -z "$GEO" ] && exit 0
        parse_geo "$GEO"
        sleep 0.20
        grim -g "$GEO" -t ppm - | open_satty "$W" "$H"
        ;;

    screen)
        grim "$FILE"
        copy_file_to_clipboard
        notify_saved
        ;;

    screen-edit)
        grim -t ppm - | satty --filename -
        ;;

    window)
        GEO="$(hyprctl activewindow -j | \
            jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        if [ -z "$GEO" ] || [ "$GEO" = "null,null nullxnull" ]; then
            notify-send "Screenshot" "No active window" -u low
            exit 1
        fi
        sleep 0.20
        grim -g "$GEO" "$FILE"
        copy_file_to_clipboard
        notify_saved
        ;;

    window-edit)
        GEO="$(hyprctl activewindow -j | \
            jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        if [ -z "$GEO" ] || [ "$GEO" = "null,null nullxnull" ]; then
            notify-send "Screenshot" "No active window" -u low
            exit 1
        fi
        parse_geo "$GEO"
        grim -g "$GEO" -t ppm - | open_satty "$W" "$H"
        ;;

    *)
        echo "Usage: $0 {area|area-edit|screen|screen-edit|window|window-edit}" >&2
        exit 1
        ;;
esac
