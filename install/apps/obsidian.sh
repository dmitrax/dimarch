#!/usr/bin/env bash
# install/apps/obsidian.sh
# Obsidian — install + apply Everforest Enchanted theme to vault(s)
#
# Usage:
#   ./obsidian.sh                        # install only
#   ./obsidian.sh ~/Workspace/my-vault   # install + apply theme to vault
#   ./obsidian.sh vault1 vault2 vault3   # apply theme to multiple vaults

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/install/utils/helpers.sh"

THEME_SRC="$REPO_ROOT/dotfiles/obsidian/.obsidian"

# ── Dependencies ────────────────────────────────────────────────────────────

if ! command -v jq &>/dev/null; then
    info "Installing jq..."
    sudo pacman -S --needed --noconfirm jq
fi

# ── Install Obsidian ────────────────────────────────────────────────────────

if pacman -Q obsidian &>/dev/null; then
    info "Obsidian already installed — skipping"
else
    info "Installing Obsidian..."
    paru -S --needed --noconfirm obsidian
fi

# ── Apply theme to vault(s) ─────────────────────────────────────────────────

apply_theme() {
    local vault="$1"

    if [[ ! -d "$vault" ]]; then
        warn "Vault not found: $vault"
        return 1
    fi

    local obsidian_dir="$vault/.obsidian"
    local themes_dir="$obsidian_dir/themes/Everforest Enchanted"
    local snippets_dir="$obsidian_dir/snippets"

    mkdir -p "$themes_dir" "$snippets_dir"

    # Theme files
    cp "$THEME_SRC/themes/Everforest Enchanted/manifest.json" "$themes_dir/"
    cp "$THEME_SRC/themes/Everforest Enchanted/theme.css"     "$themes_dir/"

    # CSS snippets
    cp "$THEME_SRC/snippets/sage.css" "$snippets_dir/"

    # Appearance — merge into existing file if present, else copy from repo
    local appearance="$obsidian_dir/appearance.json"
    if [[ -f "$appearance" ]]; then
        cp "$appearance" "$appearance.bak"
        local tmp
        tmp=$(mktemp)
        jq '. + {
            "theme": "Everforest Enchanted",
            "colorScheme": "light",
            "accentColor": "#7fb89e",
            "enabledCssSnippets": ["sage"]
        }' "$appearance" > "$tmp" && mv "$tmp" "$appearance"
    else
        cp "$THEME_SRC/appearance.json" "$appearance"
    fi

    ok "Theme applied → $vault"
}

# ── Main ────────────────────────────────────────────────────────────────────

if [[ $# -eq 0 ]]; then
    info "No vault specified — Obsidian installed, theme not applied"
    echo ""
    echo "  Apply theme to a vault:"
    echo "  $0 ~/path/to/vault"
    exit 0
fi

for vault in "$@"; do
    apply_theme "$vault"
done

info "Done"
echo ""
echo "  To apply to another vault later:"
echo "  $REPO_ROOT/install/apps/obsidian.sh ~/path/to/vault"
