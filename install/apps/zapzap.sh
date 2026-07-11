#!/usr/bin/env bash
# install/apps/zapzap.sh
# ZapZap — WhatsApp desktop client (Qt6 + QtWebEngine wrapper over WhatsApp Web)
#
# Optional app, not part of the numbered phases — install on demand.
# Source: chaotic-aur (prebuilt binary, no local AUR compile needed).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/install/utils/helpers.sh"

# ── Install ZapZap ──────────────────────────────────────────────────────────

if dimarch::is_installed zapzap; then
    info "ZapZap already installed — skipping"
else
    info "Installing ZapZap (chaotic-aur)..."
    sudo pacman -S --needed --noconfirm zapzap
    ok "ZapZap installed"
fi

# ── Done ────────────────────────────────────────────────────────────────────

info "Done"
echo ""
echo "  Multi-account and theme (dark/light) follow the system automatically —"
echo "  nothing to configure. Launch ZapZap and scan the QR code to link WhatsApp."
