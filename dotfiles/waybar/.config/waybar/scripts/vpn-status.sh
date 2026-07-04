#!/bin/bash
# WireGuard VPN status for Waybar — backed by `dimarchctl vpn status --json`
STATUS=$(dimarchctl vpn status --json 2>/dev/null)
CONNECTED=$(echo "$STATUS" | jq -r '.connected // false')
IFACE=$(echo "$STATUS" | jq -r '.interface // "wg0"')

if [ "$CONNECTED" = "true" ]; then
    echo "{\"text\":\"󰖂\",\"tooltip\":\"WireGuard (${IFACE}) — connected, click to disconnect\",\"class\":\"connected\"}"
else
    echo "{\"text\":\"󰖂\",\"tooltip\":\"WireGuard (${IFACE}) — disconnected, click to connect\",\"class\":\"disconnected\"}"
fi
