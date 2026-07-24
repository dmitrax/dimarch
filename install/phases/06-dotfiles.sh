#!/usr/bin/env bash
# =============================================================================
#  06-dotfiles.sh — Deploy dotfiles/ to $HOME
# =============================================================================
#  Run as root after 05-hyprland.sh (installs the packages these configs
#  belong to — hyprland, waybar, rofi, ghostty, zsh, starship, satty).
#
#  Written from scratch 2026-07-20. Before this script, every dotfiles/
#  subtree except the ones 05-hyprland.sh already deploys itself (swaync,
#  swayosd, yazi, swayimg, mpv, zathura, mimeapps.list) had NO deploy path
#  at all — including the entire Hyprland Lua config (dotfiles/hypr/), which
#  05-hyprland.sh installs the *package* for but never wrote to disk. A real
#  clean install would boot to a package-only Hyprland with none of DimArch's
#  actual config. Found doing this ravision — see taskboard.md "Install
#  package — ревизия".
#
#  What this script does:
#    1.  Hyprland compositor config (hyprland.lua, monitors.lua, modules/,
#        scripts/, hyprlock.conf, hyprpaper.conf, hypridle.conf(.tmpl)) +
#        enables hypridle.service (found commented "enable once" in
#        execs.lua, never actually enabled by any script)
#    2.  Waybar (config-top.jsonc, style.css, icons/, scripts/)
#    3.  rofi (config.rasi, theme.rasi)
#    4.  Ghostty (config.ghostty, light.ghostty)
#    5.  zsh (.zshrc) — sets zsh as the user's login shell
#    6.  starship prompt
#    7.  satty (screenshot annotation)
#    8.  GTK/cursor theming — settings.ini (gtk-3.0/gtk-4.0), .Xresources,
#        cursor theme wrapper — plus papirus-icon-theme + bibata-cursor-theme,
#        the packages these configs reference by name but that no script
#        installed anywhere
#    9.  Telegram .desktop override (DBusActivatable=false) — found 2026-07-20
#        that rofi's drun launch-frequency counter never increments for
#        Telegram because its packaged .desktop declares DBusActivatable=true,
#        so launches go through systemd D-Bus activation instead of a plain
#        Exec fork, bypassing rofi's history bookkeeping (confirmed via
#        /proc/<pid>/cgroup showing a dbus-*.service unit). A local override
#        in ~/.local/share/applications/ (XDG precedence over
#        /usr/share/applications/) with DBusActivatable=false restores normal
#        Exec-based launching.
#    10. XFCE helpers (xdg-terminals.list, xfce4/helpers.rc, .desktop
#        overrides) — Thunar's "Open Terminal Here" and default-app plumbing.
#        Content matched live with zero drift, just never had a deploy path.
#    11. WirePlumber — disables ALSA output auto-suspend
#        (session.suspend-timeout-seconds=0), fixes an audible pop/click on
#        codec resume when a browser tab with video creates an AudioContext.
#
#  Deploy mechanism: deploy_dotfile_tree() copies an entire dotfiles/<app>/
#  subtree file-by-file (preserving relative path + permission bits) rather
#  than listing every file by hand like 05-hyprland.sh's single-file
#  deploy_dotfile — dotfiles/hypr/ alone is ~25 files across modules/ and
#  scripts/, and a hand-maintained list drifts (see the yazi/qt6ct misses
#  found in earlier sessions, same failure mode). New files added under an
#  already-listed app/ directory are picked up automatically on next run.
#
#  Known gaps, not fixed here (different scope than "deploy dotfiles/"):
#    - dimarchctl and its companion utils (dimarch-hypridle-gen,
#      dimarch-monitor, dimarch-sleep) are not deployed to /usr/local/bin/
#      by any install script yet — zsh's vpn/vpnoff/vpnst/wg-ui aliases and
#      hypridle.conf's regeneration path (dimarchctl power apply) won't work
#      until that's written. Likely belongs in 03-base.sh (system tooling),
#      not here (user configs).
#    - ~/Pictures/wallpapers/hyprland.png (hyprpaper.conf's wallpaper path)
#      is a personal image, intentionally not tracked in the repo — hyprpaper
#      just won't find a wallpaper until one is added manually.
#    - Enpass dotfiles exist (dotfiles/enpass/) but the package (AUR-only,
#      enpass-bin) is installed nowhere — password manager choice is a
#      per-user decision, candidate for install/apps/enpass.sh like zapzap.sh,
#      not folded into this script silently.
#    - Telegram itself (the package) is installed nowhere either — same class
#      of gap as Enpass above, this script only deploys the .desktop override
#      for whichever install path put the package there.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOTFILES_DIR="${REPO_ROOT}/dotfiles"
source "${SCRIPT_DIR}/../utils/helpers.sh"

# =============================================================================
dimarch::banner "Phase 6 — Dotfiles"
# =============================================================================

dimarch::require_root

REALUSER="${SUDO_USER:-}"
REALUSER_HOME=""
if [[ -n "$REALUSER" ]]; then
    REALUSER_HOME="$(getent passwd "$REALUSER" | cut -d: -f6)"
else
    warn "Cannot detect invoking user (SUDO_USER unset) — run this script via sudo"
    warn "Dotfiles deployment and user-service steps below will be skipped"
fi

# Copies every file under dotfiles/<app>/ -> $REALUSER_HOME/... as REALUSER,
# preserving the relative path and permission bits (executable scripts stay
# executable). Skips .gitkeep placeholders. Argument is the app dir name
# under dotfiles/, e.g. "hypr" for dotfiles/hypr/.config/hypr/...
deploy_dotfile_tree() {
    local app="$1"
    local src_root="${DOTFILES_DIR}/${app}"
    local count=0

    [[ -z "$REALUSER" ]] && { warn "No user detected — skipping deploy of ${app}/"; return 0; }
    [[ -d "$src_root" ]] || { warn "Missing in repo, skipping: ${src_root}"; return 0; }

    while IFS= read -r -d '' file; do
        local rel="${file#"$src_root"/}"
        local dst="${REALUSER_HOME}/${rel}"
        sudo -u "$REALUSER" mkdir -p "$(dirname "$dst")"
        sudo -u "$REALUSER" cp -f "$file" "$dst"
        count=$((count + 1))
    done < <(find "$src_root" -type f ! -name '.gitkeep' -print0)

    ok "Deployed ${app}/ (${count} files)"
}

# =============================================================================
#  STEP 1 — Hyprland compositor config
# =============================================================================
dimarch::section "Hyprland compositor config"

deploy_dotfile_tree "hypr"

# Commented "Enable once" in execs.lua, never actually done by any script —
# hypridle must run as its own systemd user service, not as an hl.exec_cmd
# child (a second exec'd instance can bypass idle inhibitors).
if [[ -n "$REALUSER" ]]; then
    info "Enabling hypridle for user ${REALUSER}..."
    sudo -u "$REALUSER" systemctl --user enable --now hypridle.service 2>/dev/null \
        || warn "hypridle.service will need to be started manually on next login"
else
    warn "Cannot enable hypridle — run as sudo to detect user"
    warn "Run manually: systemctl --user enable --now hypridle.service"
fi

ok "Hyprland compositor config deployed"

# =============================================================================
#  STEP 2 — Waybar
# =============================================================================
dimarch::section "Waybar"

deploy_dotfile_tree "waybar"

ok "Waybar deployed"

# =============================================================================
#  STEP 3 — Launcher (rofi)
# =============================================================================
dimarch::section "Launcher (rofi)"

deploy_dotfile_tree "rofi"

ok "rofi deployed"

# =============================================================================
#  STEP 4 — Terminal (Ghostty)
# =============================================================================
dimarch::section "Terminal (Ghostty)"

deploy_dotfile_tree "ghostty"

ok "Ghostty deployed"

# =============================================================================
#  STEP 5 — Shell (zsh)
# =============================================================================
dimarch::section "Shell (zsh)"

deploy_dotfile_tree "zsh"

if [[ -n "$REALUSER" ]]; then
    ZSH_PATH="$(command -v zsh)"
    CURRENT_SHELL="$(getent passwd "$REALUSER" | cut -d: -f7)"
    if [[ "$CURRENT_SHELL" == "$ZSH_PATH" ]]; then
        info "${REALUSER} — zsh already the login shell, skipping"
    else
        chsh -s "$ZSH_PATH" "$REALUSER"
        ok "zsh set as login shell for ${REALUSER}"
        warn "Log out/in for the shell change to take effect"
    fi
else
    warn "Run manually: chsh -s \$(command -v zsh) <username>"
fi

ok "zsh deployed"

# =============================================================================
#  STEP 6 — Prompt (starship)
# =============================================================================
dimarch::section "Prompt (starship)"

deploy_dotfile_tree "starship"

ok "starship deployed"

# =============================================================================
#  STEP 7 — Screenshot annotation (satty)
# =============================================================================
dimarch::section "Screenshot annotation (satty)"

deploy_dotfile_tree "satty"

ok "satty deployed"

# =============================================================================
#  STEP 8 — GTK & cursor theming
# =============================================================================
dimarch::section "GTK & cursor theming"

# gtk-3.0/gtk-4.0 settings.ini and the .icons/default cursor wrapper all name
# these two themes directly — neither was installed by any phase script.
# papirus-icon-theme is official-repo; bibata-cursor-theme is chaotic-aur
# (provisioned by 02-cachyos.sh STEP 3, which runs before this phase).
dimarch::pacman_install \
    papirus-icon-theme \
    bibata-cursor-theme

deploy_dotfile_tree "gtk-3.0"
deploy_dotfile_tree "gtk-4.0"
deploy_dotfile_tree "xresources"
deploy_dotfile_tree "icons"

ok "GTK & cursor theming deployed"

# =============================================================================
#  STEP 9 — Telegram .desktop override (rofi history fix)
# =============================================================================
dimarch::section "Telegram .desktop override"

deploy_dotfile_tree "telegram"

if [[ -n "$REALUSER" ]]; then
    sudo -u "$REALUSER" update-desktop-database "${REALUSER_HOME}/.local/share/applications" 2>/dev/null \
        || warn "update-desktop-database failed — override may need a manual refresh"
fi

ok "Telegram .desktop override deployed"

# =============================================================================
#  STEP 10 — XFCE helpers (Thunar "Open Terminal Here", default file manager)
# =============================================================================
dimarch::section "XFCE helpers"

# xdg-terminals.list + xfce4/helpers.rc (TerminalEmulator=ghostty) + the two
# .desktop helper overrides. Content matched live with zero drift when found
# 2026-07-20 (dotfiles-deploy-script-and-repo-live-drift-found) — just never
# had a deploy path. mimeapps.list under this same tree is already deployed
# separately by 05-hyprland.sh's single-file deploy_dotfile — copying it again
# here is harmless (same content) but not the reason for this step.
deploy_dotfile_tree "xfce"

ok "XFCE helpers deployed"

# =============================================================================
#  STEP 11 — WirePlumber (disable ALSA output auto-suspend)
# =============================================================================
dimarch::section "WirePlumber auto-suspend fix"

# session.suspend-timeout-seconds defaults to 5s — WirePlumber releases the
# ALSA output node after that much silence, and re-opening it (e.g. a browser
# tab creating an AudioContext just from navigating to a page with video, even
# before playback starts) triggers an audible pop/click as the codec resumes
# from snd_hda_intel power-save. Disabling suspend for alsa_output.* nodes
# fixes it; unrelated to system sleep/hibernate (hypridle only watches input
# idle time, never audio-stream state). Confirmed live 2026-07-24.
deploy_dotfile_tree "wireplumber"

if [[ -n "$REALUSER" ]]; then
    sudo -u "$REALUSER" systemctl --user restart wireplumber 2>/dev/null \
        || warn "wireplumber restart failed — rule picks up on next login"
fi

ok "WirePlumber auto-suspend fix deployed"

# =============================================================================
dimarch::done \
    "Phase 6 complete" \
    "Log out/reboot to pick up the shell change and hypridle service. Add ~/Pictures/wallpapers/hyprland.png manually (personal image, not tracked). 07-theme.sh and 08-browser.sh still need to be written — see taskboard.md."
# =============================================================================
