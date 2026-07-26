#!/usr/bin/env bash
# install/apps/herdr.sh
# herdr — terminal workspace manager for AI coding agents (session persistence,
# multi-agent sidebar, local crash/power-cut recovery via `resume_agents_on_restore`)
#
# Optional app, not part of the numbered phases — install on demand.
# Source: AUR (herdr-bin, prebuilt binary — matches this project's package-
# source priority of prebuilt-over-local-compile; the source-build `herdr` AUR
# package has 0 votes/unverified, and the site's curl-install.sh bypasses pacman).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$REPO_ROOT/install/utils/helpers.sh"

DOTFILES_SRC="$REPO_ROOT/dotfiles/herdr"

# ── Install herdr ────────────────────────────────────────────────────────────

if dimarch::is_installed herdr-bin; then
    info "herdr already installed — skipping"
else
    info "Installing herdr-bin (AUR)..."
    paru -S --needed --noconfirm herdr-bin
    ok "herdr installed"
fi

# ── Deploy config ────────────────────────────────────────────────────────────

info "Deploying herdr config (Sage accent, popup lazygit bind, recovery settings)..."

mkdir -p "$HOME/.config/herdr"
cp -f "$DOTFILES_SRC/.config/herdr/config.toml" "$HOME/.config/herdr/config.toml"

if herdr status &>/dev/null; then
    herdr server reload-config &>/dev/null || warn "reload-config failed — restart herdr manually to pick up the new config"
    ok "Config deployed and reloaded into the running server"
else
    ok "Config deployed (will apply on next herdr launch)"
fi

# ── Claude Code integration ──────────────────────────────────────────────────

info "Wiring Claude Code integration..."
herdr integration install claude
ok "Claude Code integration installed"

# ── Done ──────────────────────────────────────────────────────────────────

info "Done"
echo ""
echo "  Launch with the 'h' alias (dotfiles/zsh/.zshrc) — reload your shell first"
echo "  (source ~/.zshrc) if this ran in an existing session."
echo ""
echo "  Recovery note: resume_agents_on_restore only resumes the herdr pane/"
echo "  session after a restart — it does not survive the local machine losing"
echo "  power itself (the agent process still dies instantly). See vault memory"
echo "  power-outage-agent-work-protection for the still-open UPS/remote-server"
echo "  questions."
