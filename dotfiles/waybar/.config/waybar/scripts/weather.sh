#!/bin/bash
# Weather via wttr.in — icon + temperature.
# Fetched as icon|temp (not the old single %c%t blob) so the icon can be
# wrapped in its own pango <span size="large"> — Waybar's custom modules
# render exec output as markup by default (escape defaults to false), so
# this bumps just the icon a bit larger without touching the temperature
# text's size, per user request 2026-07-11.
WEATHER=$(curl -sf "https://wttr.in/?format=%c|%t" 2>/dev/null | tr -d '+')
if [ -n "$WEATHER" ]; then
    ICON="${WEATHER%%|*}"
    TEMP="${WEATHER#*|}"
    echo "<span size=\"large\">${ICON}</span> ${TEMP}"
else
    echo "󰖐 N/A"
fi
