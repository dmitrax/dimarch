#!/usr/bin/env bash
# install/apps/enpass.sh
# Enpass — password manager (AUR-only, no native Wayland — runs via XWayland)
#
# Optional app, not part of the numbered phases — password manager choice is
# a per-user decision, install on demand.
#
# QT_FONT_DPI=134 baked into the .desktop files below is a value calibrated
# for this machine's specific DP-1/DP-2 fractional-scale setup — Enpass is
# a Qt app and ignores the Wayland scale factor, so the DPI has to be forced
# per-launcher. It may need retuning on different hardware/monitor setups.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/install/utils/helpers.sh"

DOTFILES_SRC="$REPO_ROOT/dotfiles/enpass"

# ── Install Enpass ───────────────────────────────────────────────────────────

if pacman -Q enpass-bin &>/dev/null; then
    info "Enpass already installed — skipping"
else
    info "Installing enpass-bin (AUR)..."
    paru -S --needed --noconfirm enpass-bin
    ok "Enpass installed"
fi

# ── Deploy dotfiles ──────────────────────────────────────────────────────────

info "Deploying Enpass autostart + launcher override..."

mkdir -p "$HOME/.config/autostart" "$HOME/.local/share/applications"
cp "$DOTFILES_SRC/.config/autostart/Enpass.desktop" "$HOME/.config/autostart/Enpass.desktop"
cp "$DOTFILES_SRC/.local/share/applications/enpass.desktop" "$HOME/.local/share/applications/enpass.desktop"

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null \
    || warn "update-desktop-database failed — launcher entry may need a manual refresh"

ok "Enpass dotfiles deployed"

# ── Done ──────────────────────────────────────────────────────────────────

info "Done"
echo ""
echo "  Launch Enpass to set up or unlock your vault. Autostart is enabled"
echo "  (12s delay, starts minimized) — disable via the .desktop file in"
echo "  ~/.config/autostart/ if you don't want that."
