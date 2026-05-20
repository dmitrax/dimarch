#!/usr/bin/env bash

set -euo pipefail

SCREENSHOT_DIR="${XDG_SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP="$(date +'%Y-%m-%d_%H-%M-%S')"
FILE="$SCREENSHOT_DIR/Screenshot_${TIMESTAMP}.png"

MODE="${1:-area}"

notify_saved() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Screenshot saved" "$FILE"
    fi
}

copy_file_to_clipboard() {
    wl-copy --type image/png < "$FILE"
}

select_region() {
    slurp \
        -d \
        -b 00000055 \
        -c 2f7d68ff \
        -w 2
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

        sleep 0.20
	# Edit mode: do NOT auto-save.
        # Satty opens the screenshot as a floating editor window.
        grim -g "$GEO" -t ppm - | satty --filename -
        ;;

    screen)
        grim "$FILE"
        copy_file_to_clipboard
        notify_saved
        ;;

    screen-edit)
        # Edit mode: do NOT auto-save.
        grim -t ppm - | satty --filename -
        ;;

    *)
        echo "Usage: $0 {area|area-edit|screen|screen-edit}" >&2
        exit 1
        ;;
esac
