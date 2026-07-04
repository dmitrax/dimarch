#!/usr/bin/env bash
# =============================================================================
#  setup-wireguard.sh — WireGuard VPN client for DimArch OS
# =============================================================================
#
#  Run as root. Idempotent — safe to re-run.
#
#  What this script does:
#    1. Installs wireguard-tools, openresolv, networkmanager, network-manager-applet
#    2. Enables and starts NetworkManager.service
#    3. Imports the WireGuard config (dimarch.conf [vpn] wg_conf_path) into
#       NetworkManager as connection `interface` (default wg0)
#    4. Disables autoconnect — VPN starts manually, never on boot
#
#  Prerequisites:
#    - dimarch.conf [vpn] enable = true
#    - Your own config downloaded from your WireGuard admin UI (e.g. wg-easy),
#      placed at [vpn] wg_conf_path (default /etc/wireguard/wg0.conf).
#      This file contains private keys — it is never part of the dimarch repo.
#
#  Usage:
#    sudo ./setup-wireguard.sh
#
#  Toggle afterwards: dimarchctl vpn status|up|down|toggle|ui
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"

dimarch::require_root
dimarch::banner "setup-wireguard — VPN client"

# =============================================================================
#  Load dimarch.conf
# =============================================================================

dimarch::section "Configuration"

DIMARCH_CONF="${DIMARCH_CONF:-/etc/dimarch.conf}"

if [[ ! -f "$DIMARCH_CONF" ]]; then
    REPO_CONF="${SCRIPT_DIR}/../../dimarch.conf"
    if [[ -f "$REPO_CONF" ]]; then
        info "Deploying dimarch.conf → /etc/dimarch.conf"
        install -m 644 "$REPO_CONF" /etc/dimarch.conf
        DIMARCH_CONF=/etc/dimarch.conf
    else
        die "dimarch.conf not found.\n  Copy dimarch.conf.example → dimarch.conf, fill in your values, then re-run."
    fi
fi

ok "Config: ${DIMARCH_CONF}"

ENABLE=$(dimarch::conf_get vpn enable "$DIMARCH_CONF");        ENABLE=${ENABLE:-false}
if [[ "$ENABLE" != "true" ]]; then
    die "[vpn] enable is not 'true' in ${DIMARCH_CONF} — set it, then re-run."
fi

IFACE=$(dimarch::conf_get vpn interface "$DIMARCH_CONF");      IFACE=${IFACE:-wg0}
WG_CONF=$(dimarch::conf_get vpn wg_conf_path "$DIMARCH_CONF"); WG_CONF=${WG_CONF:-/etc/wireguard/wg0.conf}

info "Interface:  ${IFACE}"
info "Config:     ${WG_CONF}"

# =============================================================================
#  Packages
# =============================================================================

dimarch::section "Packages"

dimarch::pacman_install wireguard-tools openresolv networkmanager network-manager-applet

# =============================================================================
#  NetworkManager
# =============================================================================

dimarch::section "NetworkManager"

dimarch::enable_service NetworkManager.service

# resolvconf signature mismatch on first run — harmless to regenerate.
resolvconf -u 2>/dev/null || true

# =============================================================================
#  Import WireGuard config
# =============================================================================

dimarch::section "WireGuard config"

if [[ ! -f "$WG_CONF" ]]; then
    warn "Config not found: ${WG_CONF}"
    info "Download it from your WireGuard admin UI, place it there, then re-run this script."
else
    if nmcli -t -f NAME connection show 2>/dev/null | grep -qx "$IFACE"; then
        ok "NetworkManager connection '${IFACE}' already imported"
    else
        nmcli connection import type wireguard file "$WG_CONF"
        ok "Imported '${IFACE}' into NetworkManager"
    fi

    nmcli connection modify "$IFACE" connection.autoconnect no
    ok "autoconnect disabled — VPN starts manually only"
fi

# =============================================================================
#  Done
# =============================================================================

dimarch::done \
    "WireGuard client ready" \
    "Toggle: dimarchctl vpn up|down|status — or nm-applet in the Waybar tray"
