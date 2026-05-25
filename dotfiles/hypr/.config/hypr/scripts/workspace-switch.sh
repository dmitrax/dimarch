#!/bin/bash
# Switch workspace — Hyprland 0.55 Lua dispatch compatible

case "$1" in
    next)
        CURRENT=$(hyprctl activeworkspace -j | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
        NEXT=$((CURRENT + 1))
        if [ $NEXT -gt 7 ]; then NEXT=1; fi
        hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = '$NEXT' }))"
        ;;
    prev)
        CURRENT=$(hyprctl activeworkspace -j | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
        PREV=$((CURRENT - 1))
        if [ $PREV -lt 1 ]; then PREV=7; fi
        hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = '$PREV' }))"
        ;;
    *)
        hyprctl eval "hl.dispatch(hl.dsp.focus({ workspace = '$1' }))"
        ;;
esac
