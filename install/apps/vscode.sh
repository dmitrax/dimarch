#!/usr/bin/env bash
# install/apps/vscode.sh
# VS Code — install, extensions, settings
#
# Run separately after phases 01-09 complete
# Requires: paru available, internet connection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/install/utils/helpers.sh"

SETTINGS_SRC="$REPO_ROOT/dotfiles/vscode/settings.json"
SETTINGS_DST="$HOME/.config/Code/User/settings.json"
EXTENSIONS_FILE="$REPO_ROOT/dotfiles/vscode/extensions.txt"

# ── Install VS Code ─────────────────────────────────────────────────────────

if pacman -Q visual-studio-code-bin &>/dev/null || pacman -Q code &>/dev/null; then
    info "VS Code already installed — skipping"
else
    info "Installing VS Code..."
    paru -S --needed --noconfirm visual-studio-code-bin
fi

# ── Settings ────────────────────────────────────────────────────────────────

info "Deploying settings.json..."
mkdir -p "$(dirname "$SETTINGS_DST")"

if [[ -f "$SETTINGS_DST" ]]; then
    cp "$SETTINGS_DST" "${SETTINGS_DST%.json}.bak.json"
    info "Backed up existing settings → settings.bak.json"
fi

cp "$SETTINGS_SRC" "$SETTINGS_DST"
info "settings.json → $SETTINGS_DST"

# ── Extensions ──────────────────────────────────────────────────────────────

if ! command -v code &>/dev/null; then
    warn "'code' CLI not found — launch VS Code once, then re-run"
    exit 1
fi

info "Installing extensions..."
failed=()

while IFS= read -r ext; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    if code --install-extension "$ext" --force &>/dev/null; then
        info "  ✓ $ext"
    else
        warn "  ✗ $ext"
        failed+=("$ext")
    fi
done < "$EXTENSIONS_FILE"

if [[ ${#failed[@]} -gt 0 ]]; then
    warn "Failed — retry manually:"
    for ext in "${failed[@]}"; do
        echo "  code --install-extension $ext"
    done
fi

# ── Done ────────────────────────────────────────────────────────────────────

info "VS Code ready"
echo ""
echo "  Next: sign in to Settings Sync"
echo "  Accounts (bottom-left) → Turn on Settings Sync → GitHub"
