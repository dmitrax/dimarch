#!/usr/bin/env bash
# =============================================================================
#  06-hyprland.sh — Hyprland desktop stack
# =============================================================================
#  Run as root after 03-base.sh (Qt/GTK portals, hyprpolkitagent, audio) and
#  04-snapper.sh. Full rewrite (not a patch) of the legacy version, which
#  installed mako + Dolphin + full KIO — both contradict accepted decisions
#  (swaync, Thunar) and the script had no set -euo pipefail / --noconfirm,
#  so it hung on an automated run. See taskboard.md "Install package —
#  ревизия" and decision-install-package-first-instead-of-phase1-because-
#  stale-scripts-block-clean-install.md.
#
#  What this script does:
#    1.  Hyprland core — compositor, portal, session, lock/idle/wallpaper
#    2.  Panel & launcher — Waybar, rofi, libnotify
#    3.  Notification center — swaync (Sage theme, deployed from dotfiles/)
#    4.  OSD — swayosd (Sage theme + libinput backend service)
#    5.  File managers — Thunar + yazi + tumbler (no Dolphin/KIO)
#    6.  Default apps — mousepad, swayimg, mpv (+ mpv-mpris, mpv-uosc)
#    7.  Default app associations — mimeapps.list
#    8.  Screenshot — grim, slurp, satty, wl-clipboard
#    9.  Terminal & shell — Ghostty, zsh, starship, fonts
#    10. Terminal tools — eza, bat, fzf, zoxide, git-delta, tealdeer, lazygit
#    11. System utilities — socat, python, gparted, xhost, gnome-keyring
#    12. Input group — required for Waybar's keyboard-state (CapsLock) module
#    13. AUR extras — hyprland-per-window-layout
#
#  nerd-fonts-inter (STEP 9) and mpv-uosc (STEP 6) both live in chaotic-aur —
#  provisioned by 02-cachyos.sh STEP 3, which must run before this script
#  (phase order 01→09 guarantees that on a real install run).
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
DOTFILES_DIR="${REPO_ROOT}/dotfiles"
source "${SCRIPT_DIR}/../utils/helpers.sh"

# =============================================================================
dimarch::banner "Phase 6 — Hyprland desktop stack"
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

# Copies dotfiles/<app>/.config/... -> $REALUSER_HOME/.config/... as REALUSER.
# Argument is the path relative to dotfiles/, e.g. "swayimg/.config/swayimg/init.lua".
deploy_dotfile() {
    local rel="$1"
    local src="${DOTFILES_DIR}/${rel}"
    local dst="${REALUSER_HOME}/${rel#*/}"

    [[ -z "$REALUSER" ]] && { warn "No user detected — skipping deploy of ${rel}"; return 0; }
    [[ -f "$src" ]] || { warn "Missing in repo, skipping: ${src}"; return 0; }

    sudo -u "$REALUSER" mkdir -p "$(dirname "$dst")"
    sudo -u "$REALUSER" cp -f "$src" "$dst"
    ok "Deployed ${rel#*/}"
}

# =============================================================================
#  STEP 1 — Hyprland core
# =============================================================================
dimarch::section "Hyprland core"

dimarch::pacman_install \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    xdg-desktop-portal-hyprland \
    uwsm \
    wlopm

ok "Hyprland core installed"

# =============================================================================
#  STEP 2 — Panel & launcher
# =============================================================================
dimarch::section "Panel & launcher"

dimarch::pacman_install \
    rofi-wayland \
    waybar-git \
    libnotify

ok "Panel & launcher installed"

# =============================================================================
#  STEP 3 — Notification center (swaync)
# =============================================================================
dimarch::section "Notification center (swaync)"

# Replaces mako (legacy script) — see
# decision-install-package-first-instead-of-phase1-because-stale-scripts-
# block-clean-install.md. Brought forward from Phase 1 into the install
# package 2026-07-09 after live testing (theme, DND, grouping, Waybar
# integration all confirmed working) — see taskboard.md.
dimarch::pacman_install swaync

deploy_dotfile "swaync/.config/swaync/config.json"
deploy_dotfile "swaync/.config/swaync/style.css"

if [[ -n "$REALUSER" ]]; then
    info "Enabling swaync for user ${REALUSER}..."
    sudo -u "$REALUSER" systemctl --user enable --now swaync.service 2>/dev/null \
        || warn "swaync.service will start automatically on login"
else
    warn "Cannot enable swaync — run as sudo to detect user"
    warn "Run manually: systemctl --user enable --now swaync.service"
fi

ok "swaync installed and themed"

# =============================================================================
#  STEP 4 — OSD (swayosd)
# =============================================================================
dimarch::section "On-screen display (swayosd)"

dimarch::pacman_install swayosd

deploy_dotfile "swayosd/.config/swayosd/style.css"

# System-level service — detects CapsLock/ScrollLock/volume via evdev,
# independent of any Hyprland keybind. Found disabled live 2026-07-09.
dimarch::enable_service swayosd-libinput-backend.service

ok "swayosd installed, themed, libinput backend enabled"

# =============================================================================
#  STEP 5 — File managers
# =============================================================================
dimarch::section "File managers"

# Thunar (GUI) + yazi (terminal) — replaces Dolphin + full KIO stack
# (kio/kio-extras/kio-admin). See
# decision-thunar-instead-of-dolphin-because-no-kio-dependency.md.
# tumbler is Thunar's own thumbnailer daemon (XFCE/GTK), not KDE's
# ffmpegthumbs — ffmpegthumbnailer itself is already installed by
# 03-base.sh STEP 8 (codecs) and plugs into tumbler automatically.
# gvfs — virtual filesystem backend, required for Thunar's trash and
# network-location browsing (silently broken without it, not an optional
# extra). thunar-volman — Thunar's own device-insertion handling
# (complements, doesn't replace, udiskie's tray auto-mount from
# 03-base.sh). thunar-archive-plugin — right-click Extract/Compress,
# pairs with file-roller (03-base.sh archive utilities). glycin —
# GNOME sandboxed image decoder, registers tumbler .thumbnailer entries
# for HEIF/JPEG XL/SVG/other image-rs formats; ffmpegthumbnailer (03-base.sh)
# only covers video, not these image formats.
dimarch::pacman_install \
    thunar \
    yazi \
    tumbler \
    gvfs \
    thunar-volman \
    thunar-archive-plugin \
    glycin

ok "File managers installed"

# =============================================================================
#  STEP 6 — Default apps
# =============================================================================
dimarch::section "Default apps"

# mousepad (text editor) — unchanged from XFCE.
# swayimg (image viewer) — replaces Ristretto, Wayland-native + Lua-configurable.
#   See decision-swayimg-instead-of-ristretto-because-wayland-native-lua-configurable.md.
# mpv + mpv-mpris (video player) — replaces Celluloid, drops the GTK4/libadwaita tail.
#   See decision-mpv-instead-of-celluloid-because-gtk-tail.md.
dimarch::pacman_install \
    mousepad \
    swayimg \
    mpv \
    mpv-mpris

deploy_dotfile "swayimg/.config/swayimg/init.lua"
deploy_dotfile "mpv/.config/mpv/mpv.conf"

# mpv-uosc (chaotic-aur) — custom OSC theme (Sage, QuickTime-style controls).
# See the chaotic-aur dependency note at the top of this file.
dimarch::pacman_install mpv-uosc

deploy_dotfile "mpv/.config/mpv/script-opts/uosc.conf"

# mpv-uosc ships its scripts/fonts under /usr/share/mpv/ — symlinked (not
# copied) into ~/.config/mpv so `pacman -Syu mpv-uosc` keeps them current.
# These targets are package-owned, not part of dotfiles/, so deploy_dotfile
# doesn't apply — same reasoning as uosc.conf's own top-of-file comment.
if [[ -n "$REALUSER" ]]; then
    sudo -u "$REALUSER" mkdir -p "${REALUSER_HOME}/.config/mpv/scripts" "${REALUSER_HOME}/.config/mpv/fonts"
    sudo -u "$REALUSER" ln -sf /usr/share/mpv/scripts/uosc "${REALUSER_HOME}/.config/mpv/scripts/uosc"
    sudo -u "$REALUSER" ln -sf /usr/share/mpv/fonts/uosc_icons.otf "${REALUSER_HOME}/.config/mpv/fonts/uosc_icons.otf"
    sudo -u "$REALUSER" ln -sf /usr/share/mpv/fonts/uosc_textures.ttf "${REALUSER_HOME}/.config/mpv/fonts/uosc_textures.ttf"
    ok "mpv-uosc scripts/fonts symlinked"
else
    warn "No user detected — mpv-uosc symlinks not created, see this script's header"
fi

ok "Default apps installed"

# =============================================================================
#  STEP 7 — Default app associations
# =============================================================================
dimarch::section "Default app associations (mimeapps.list)"

deploy_dotfile "xfce/.config/mimeapps.list"

ok "mimeapps.list deployed"

# =============================================================================
#  STEP 8 — Screenshot
# =============================================================================
dimarch::section "Screenshot tools"

dimarch::pacman_install \
    grim \
    slurp \
    satty \
    wl-clipboard

ok "Screenshot tools installed"

# =============================================================================
#  STEP 9 — Terminal & shell
# =============================================================================
dimarch::section "Terminal & shell"

# nerd-fonts-inter (chaotic-aur) replaces the legacy script's plain
# "inter-font" — same Inter family, patched with Nerd Font glyphs, needed
# wherever dotfiles reference "Inter Variable" alongside icon glyphs
# (rofi, swaync, swayosd). See the chaotic-aur dependency note above.
dimarch::pacman_install \
    ghostty \
    zsh \
    starship \
    ttf-jetbrains-mono-nerd \
    nerd-fonts-inter

ok "Terminal & shell installed"

# =============================================================================
#  STEP 10 — Terminal tools
# =============================================================================
dimarch::section "Terminal tools"

dimarch::pacman_install \
    eza \
    bat \
    fzf \
    zoxide \
    git-delta \
    tealdeer \
    lazygit

ok "Terminal tools installed"

# =============================================================================
#  STEP 11 — System utilities
# =============================================================================
dimarch::section "System utilities"

dimarch::pacman_install \
    socat \
    python \
    gparted \
    xorg-xhost \
    gnome-keyring

ok "System utilities installed"

# =============================================================================
#  STEP 12 — Input group (Waybar CapsLock indicator)
# =============================================================================
dimarch::section "Input group"

# Waybar's keyboard-state module reads libevdev LED state directly and
# needs the user in the `input` group — otherwise it fails silently
# (EACCES, module just shows nothing). Found live 2026-07-09. This is the
# only phase script that manages the `input` group (wheel/etc. are set up
# by the base Arch install, before any DimArch script runs).
if [[ -n "$REALUSER" ]]; then
    if id -nG "$REALUSER" | grep -qw input; then
        info "${REALUSER} already in 'input' group — skipping"
    else
        usermod -aG input "$REALUSER"
        ok "${REALUSER} added to 'input' group"
        warn "Log out (or reboot) for group membership to take effect"
    fi
else
    warn "Run manually: sudo usermod -aG input <username>"
fi

# =============================================================================
#  STEP 13 — AUR extras
# =============================================================================
dimarch::section "AUR extras"

dimarch::paru_install hyprland-per-window-layout

ok "AUR extras installed"

# =============================================================================
dimarch::done \
    "Phase 6 complete" \
    "Log out/reboot if the input group was just added. 05-gpu.sh, 07-dotfiles.sh, 08-theme.sh, 09-browser.sh still need to be written before a full clean-install run — see taskboard.md."
# =============================================================================
