#!/usr/bin/env bash
# =============================================================================
#  setup-link-router.sh — Zoom-direct link router for DimArch OS
# =============================================================================
#
#  Run as your normal user (NOT root). Idempotent — safe to re-run.
#
#  What this script does:
#    1. Copies zoom-link-handler + link-router into ~/.local/bin/
#    2. Copies link-router.desktop into ~/.local/share/applications/,
#       substituting the real $HOME into its Exec= line
#    3. Registers it as the default handler for x-scheme-handler/https
#       and x-scheme-handler/http via `xdg-mime default`
#
#  Why: Zoom's Linux client has a render-layer bug that reliably crashes
#  or hangs when a meeting is joined via a browser-mediated link (the
#  usual xdg-open → browser → zoommtg:// deep-link chain). Joining
#  directly through the Zoom app's own Join dialog avoids it. This
#  router automates that: any zoom.us join link is converted straight
#  to a zoommtg:// deep link and handed to Zoom, skipping the browser
#  entirely. Every other http(s) link falls through to a rofi picker
#  among installed browsers (auto-discovered from .desktop files, so
#  installing/removing a browser needs no changes here), and jumps to
#  whichever Hyprland workspace the chosen browser opens on.
#  Full background: docs/link-router.md
#
#  Usage:
#    ./setup-link-router.sh
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers.sh
source "${SCRIPT_DIR}/helpers.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOTFILES_SRC="${REPO_ROOT}/dotfiles/link-router"

dimarch::require_user
dimarch::banner "setup-link-router — Zoom-direct link router"

# =============================================================================
#  Deploy scripts + desktop entry
# =============================================================================

dimarch::section "Deploying files"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

install -m 755 "${DOTFILES_SRC}/.local/bin/zoom-link-handler" "$HOME/.local/bin/zoom-link-handler"
install -m 755 "${DOTFILES_SRC}/.local/bin/link-router" "$HOME/.local/bin/link-router"
dimarch::ok "~/.local/bin/{zoom-link-handler,link-router}"

sed "s|__HOME__|${HOME}|g" \
    "${DOTFILES_SRC}/.local/share/applications/link-router.desktop" \
    > "$HOME/.local/share/applications/link-router.desktop"
dimarch::ok "~/.local/share/applications/link-router.desktop"

update-desktop-database "$HOME/.local/share/applications/" 2>/dev/null || true

# =============================================================================
#  Register as default http(s) handler
# =============================================================================

dimarch::section "Registering as default link handler"

xdg-mime default link-router.desktop x-scheme-handler/https
xdg-mime default link-router.desktop x-scheme-handler/http
dimarch::ok "x-scheme-handler/https, x-scheme-handler/http -> link-router.desktop"

# =============================================================================
#  Done
# =============================================================================

dimarch::done \
    "Link router installed" \
    "Zoom join links now skip the browser; everything else prompts a browser picker"
