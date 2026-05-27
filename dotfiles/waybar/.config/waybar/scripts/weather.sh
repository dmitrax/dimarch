#!/bin/bash
# Weather via wttr.in — icon + temperature
WEATHER=$(curl -sf "https://wttr.in/?format=%c%t" 2>/dev/null | tr -d '+')
if [ -n "$WEATHER" ]; then
    echo "$WEATHER"
else
    echo "󰖐 N/A"
fi
